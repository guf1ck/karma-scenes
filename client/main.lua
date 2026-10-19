local scenes, nearby = {}, {}
local placing, editing, point, pending = false, false, nil, nil
local requestCounter, nuiReady = 0, false

local function notify(message, notifyType, duration)
    local ok, err = pcall(Config.Notify, message, notifyType or 'error', duration or 4500)
    if not ok then print('[karma-scenes] Notification function failed: ' .. tostring(err)) end
end
RegisterNetEvent('karma-scenes:notify', notify)

local function closeEditor()
    editing = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openEditor(draft)
    placing, editing = false, true
    SendNUIMessage({ action = 'placement', show = false })
    SendNUIMessage({ action = 'open', colors = Config.Colors, sizes = Config.Sizes,
        distances = Config.Distances, defaults = Config.Defaults,
        maxLength = Config.MaxTextLength, draft = draft })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ready', function(_, cb)
    nuiReady = true
    cb({ ok = true })
end)
RegisterNUICallback('clickSound', function(_, cb)
    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    cb({ ok = true })
end)
RegisterNUICallback('close', function(_, cb)
    closeEditor()
    point = nil
    cb({ ok = true })
end)
RegisterNUICallback('submit', function(data, cb)
    if not editing or not point or pending then return cb({ ok = false, error = 'No active placement.' }) end
    data.coords = { x = point.x, y = point.y, z = point.z }
    local clean, err = SceneRules.payload(data)
    if not clean then return cb({ ok = false, error = err }) end
    requestCounter = requestCounter + 1
    pending = { id = requestCounter, draft = clean }
    closeEditor()
    TriggerServerEvent('karma-scenes:create', requestCounter, clean)
    cb({ ok = true })
    local sent = requestCounter
    SetTimeout(10000, function()
        if pending and pending.id == sent then
            pending, point = nil, nil
            notify('No response from the server. Check your connection before placing again.')
            TriggerServerEvent('karma-scenes:requestSync')
        end
    end)
end)

RegisterNetEvent('karma-scenes:result', function(id, ok, message)
    if not pending or pending.id ~= id then return end
    local draft = pending.draft
    pending = nil
    notify(message, ok and 'success' or 'error')
    if not ok and not IsEntityDead(PlayerPedId()) and point
        and #(GetEntityCoords(PlayerPedId()) - point) <= Config.PlacementDistance then
        -- Let the short closing animation finish before showing a rejected draft.
        SetTimeout(220, function()
            if point and not placing and not editing and not pending then openEditor(draft) end
        end)
    else point = nil end
end)

local function wrapText(text)
    local lines, current, count = {}, '', 0
    -- Bound each text component and wrap long words safely at UTF-8 boundaries.
    for _, code in utf8.codes(text) do
        local character = utf8.char(code)
        if count >= 44 and (character == ' ' or count >= 52) then
            lines[#lines + 1], current, count = current, '', 0
        end
        if current ~= '' or character ~= ' ' then current, count = current .. character, count + 1 end
    end
    if current ~= '' then lines[#lines + 1] = current end
    return lines
end

local function prepare(scene)
    scene.position = vector3(scene.coords.x, scene.coords.y, scene.coords.z + Config.TextHeight)
    scene.lines = wrapText(scene.text)
    scene.rgb = SceneRules.option(Config.Colors, scene.color).rgb
    scene.scale = SceneRules.option(Config.Sizes, scene.size).scale
    scene.range = SceneRules.option(Config.Distances, scene.distance).meters
    return scene
end
RegisterNetEvent('karma-scenes:snapshot', function(list)
    scenes, nearby = {}, {}
    for _, scene in ipairs(list) do scenes[scene.id] = prepare(scene) end
end)
RegisterNetEvent('karma-scenes:upsert', function(scene) scenes[scene.id] = prepare(scene) end)
RegisterNetEvent('karma-scenes:remove', function(id) scenes[id] = nil end)

RegisterCommand(Config.Command, function()
    if placing then placing = false; SendNUIMessage({ action = 'placement', show = false }); return end
    if editing or pending then return end
    if not nuiReady then return notify('Scene editor is loading. Try again in a moment.') end
    if IsEntityDead(PlayerPedId()) or IsPedInAnyVehicle(PlayerPedId(), false) then return notify('Stand on foot to place a scene.') end
    placing, point = true, nil
    SendNUIMessage({ action = 'placement', show = true })
end, false)

RegisterCommand(Config.RemoveCommand, function()
    if placing or editing then return end
    local coords, target, best = GetEntityCoords(PlayerPedId()), nil, Config.RemoveDistance
    for id, scene in pairs(scenes) do
        local distance = SceneRules.distance(coords, scene.coords)
        if scene.canRemove and distance <= best then target, best = id, distance end
    end
    if target then TriggerServerEvent('karma-scenes:remove', target)
    else notify(('No scene you can remove within %.0f meters.'):format(Config.RemoveDistance)) end
end, false)

CreateThread(function()
    local ray, hitPoint
    while true do
        if placing then
            Wait(0)
            DisablePlayerFiring(PlayerId(), true)
            for _, control in ipairs({ 24, 25, 38, 200, 202 }) do DisableControlAction(0, control, true) end
            if IsEntityDead(PlayerPedId()) or IsPedInAnyVehicle(PlayerPedId(), false)
                or IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 202) then
                placing, point, ray, hitPoint = false, nil, nil, nil
                SendNUIMessage({ action = 'placement', show = false })
            else
                if ray then
                    local state, hit, coords = GetShapeTestResult(ray)
                    if state ~= 1 then
                        ray = nil
                        hitPoint = state == 2 and (hit == 1 or hit == true) and coords or nil
                    end
                end
                if not ray then
                    local cam, rotation = GetGameplayCamCoord(), GetGameplayCamRot(2)
                    local pitch, yaw = math.rad(rotation.x), math.rad(rotation.z)
                    local direction = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
                    local destination = cam + direction * (Config.PlacementDistance + 5.0)
                    -- Trace static world and objects; ignore players and vehicles.
                    ray = StartShapeTestRay(cam.x, cam.y, cam.z, destination.x, destination.y, destination.z, 17, PlayerPedId(), 7)
                end
                local valid = hitPoint and #(GetEntityCoords(PlayerPedId()) - hitPoint) <= Config.PlacementDistance
                if valid then
                    DrawMarker(28, hitPoint.x, hitPoint.y, hitPoint.z + 0.035, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.MarkerSize, Config.MarkerSize, Config.MarkerSize, 255, 0, 0, 235, false, false, 2, false, nil, nil, false)
                end
                if IsDisabledControlJustPressed(0, 38) or IsControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 24) then
                    if valid then point = hitPoint; ray, hitPoint = nil, nil; openEditor()
                    else notify('Aim at a surface within reach.') end
                end
            end
        else
            ray, hitPoint = nil, nil
            Wait(150)
        end
    end
end)

CreateThread(function()
    while true do
        local coords, list = GetEntityCoords(PlayerPedId()), {}
        for id, scene in pairs(scenes) do
            if #(coords - scene.position) <= scene.range + 2.0 then list[#list + 1] = id end
        end
        nearby = list
        if editing and (IsEntityDead(PlayerPedId()) or (point and #(coords - point) > Config.PlacementDistance + 1.0)) then
            closeEditor(); point = nil
        end
        Wait(400)
    end
end)

CreateThread(function()
    while true do
        if #nearby == 0 then Wait(250)
        else
            Wait(0)
            local coords, cam = GetEntityCoords(PlayerPedId()), GetGameplayCamCoord()
            for _, id in ipairs(nearby) do
                local scene = scenes[id]
                if scene then
                    local distance = #(coords - scene.position)
                    local visible, x, y = World3dToScreen2d(scene.position.x, scene.position.y, scene.position.z)
                    if visible and distance <= scene.range and not IsPauseMenuActive() then
                        local cameraDistance = #(cam - scene.position)
                        local scale = scene.scale * math.max(0.65, math.min(1.2, 4.0 / math.max(cameraDistance, 1.0)))
                        local alpha = math.floor(255 * math.min(1.0, (scene.range - distance) / 0.8))
                        for line, text in ipairs(scene.lines) do
                            SetTextFont(0)
                            SetTextScale(0.0, scale)
                            SetTextColour(scene.rgb[1], scene.rgb[2], scene.rgb[3], alpha)
                            SetTextCentre(true)
                            SetTextDropshadow(1, 0, 0, 0, alpha)
                            SetTextOutline()
                            BeginTextCommandDisplayText('STRING')
                            AddTextComponentSubstringPlayerName(text)
                            EndTextCommandDisplayText(x, y + (line - 1) * scale * 0.043)
                        end
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(500) end
    TriggerServerEvent('karma-scenes:requestSync')
    TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'Place text in the world. Aim, then press E.')
    TriggerEvent('chat:addSuggestion', '/' .. Config.RemoveCommand, 'Remove your nearest scene.')
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    if editing then SetNuiFocus(false, false) end
    TriggerEvent('chat:removeSuggestion', '/' .. Config.Command)
    TriggerEvent('chat:removeSuggestion', '/' .. Config.RemoveCommand)
end)
