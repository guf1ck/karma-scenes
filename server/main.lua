local scenes, nextId, cooldowns, subscribers = {}, 1, {}, {}
local resource = GetCurrentResourceName()
local storage = 'data/scenes.json'

local function ownerOf(src)
    return GetPlayerIdentifierByType(src, 'license')
end

local function notify(src, message, notifyType)
    TriggerClientEvent('karma-scenes:notify', src, message, notifyType or 'error')
end

local function save()
    if not Config.Persistence then return true end
    local rows = {}
    for _, scene in pairs(scenes) do rows[#rows + 1] = scene end
    local ok = SaveResourceFile(resource, storage, json.encode({ version = 1, nextId = nextId, scenes = rows }), -1)
    if not ok then print('[karma-scenes] ERROR: could not save data/scenes.json. Check resource folder permissions.') end
    return ok
end

local function publicScene(scene, src)
    return { id = scene.id, text = scene.text, coords = scene.coords, color = scene.color,
        size = scene.size, distance = scene.distance,
        canRemove = scene.owner == ownerOf(src) or IsPlayerAceAllowed(src, Config.AdminAce) }
end

local function sync(src)
    local bucket, list = GetPlayerRoutingBucket(src), {}
    for _, scene in pairs(scenes) do
        if scene.bucket == bucket then list[#list + 1] = publicScene(scene, src) end
    end
    subscribers[src] = bucket
    TriggerClientEvent('karma-scenes:snapshot', src, list)
end

local function publish(scene, event)
    for src in pairs(subscribers) do
        if GetPlayerRoutingBucket(src) == scene.bucket then
            TriggerClientEvent(event, src, event == 'karma-scenes:upsert' and publicScene(scene, src) or scene.id)
        end
    end
end

local function limited(src, action, seconds)
    cooldowns[src] = cooldowns[src] or {}
    local now = os.time()
    if cooldowns[src][action] and now - cooldowns[src][action] < seconds then return true end
    cooldowns[src][action] = now
    return false
end

local function load()
    if not Config.Persistence then return end
    local raw = LoadResourceFile(resource, storage)
    if not raw or raw == '' then return end
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' or type(data.scenes) ~= 'table' then
        print('[karma-scenes] Invalid save file. A recovery copy will be preserved.')
        if not SaveResourceFile(resource, 'data/scenes-recovery-' .. os.time() .. '.json', raw, -1) then
            error('Cannot preserve corrupt scene data. Repair data/scenes.json before restarting.')
        end
        return
    end
    local total = 0
    for _, row in ipairs(data.scenes) do
        local clean = SceneRules.payload(row)
        if clean and type(row.owner) == 'string' and SceneRules.integer(row.id) and row.id > 0
            and SceneRules.integer(row.bucket)
            and type(row.expiresAt) == 'number' and (row.expiresAt == 0 or row.expiresAt > os.time())
            and not scenes[row.id] and total < Config.MaxScenes then
            clean.id, clean.owner, clean.bucket = row.id, row.owner, row.bucket
            clean.expiresAt = row.expiresAt
            scenes[clean.id] = clean
            nextId = math.max(nextId, clean.id + 1)
            total = total + 1
        end
    end
end
load()

RegisterNetEvent('karma-scenes:requestSync', function()
    local src = source
    if not limited(src, 'sync', 3) then sync(src) end
end)

RegisterNetEvent('karma-scenes:create', function(requestId, data)
    local src = source
    if not SceneRules.integer(requestId) then return end
    local function result(ok, message)
        TriggerClientEvent('karma-scenes:result', src, requestId, ok, message)
    end
    if limited(src, 'create', Config.CooldownSeconds) then return result(false, 'Wait a moment before placing another scene.') end
    if Config.CreateAce and not IsPlayerAceAllowed(src, Config.CreateAce) then return result(false, 'You cannot create scenes.') end
    local owner, ped = ownerOf(src), GetPlayerPed(src)
    if not owner or ped == 0 or GetEntityHealth(ped) <= 0 then return result(false, 'Your player is not ready.') end
    local clean, err = SceneRules.payload(data)
    if not clean then return result(false, err) end
    if SceneRules.distance(GetEntityCoords(ped), clean.coords) > Config.PlacementDistance + 1.0 then
        return result(false, 'That placement is too far away.')
    end
    local owned, total = 0, 0
    for _, scene in pairs(scenes) do
        total = total + 1
        if scene.owner == owner then owned = owned + 1 end
    end
    if owned >= Config.MaxPerPlayer then return result(false, 'Remove one of your old scenes first.') end
    if total >= Config.MaxScenes then return result(false, 'The server scene limit has been reached.') end
    clean.id, clean.owner, clean.bucket = nextId, owner, GetPlayerRoutingBucket(src)
    clean.expiresAt = Config.LifetimeHours > 0 and os.time() + math.floor(Config.LifetimeHours * 3600) or 0
    nextId = nextId + 1
    scenes[clean.id] = clean
    if not save() then
        scenes[clean.id] = nil
        return result(false, 'Scene could not be saved. Please contact an administrator.')
    end
    publish(clean, 'karma-scenes:upsert')
    result(true, 'Scene placed.')
end)

RegisterNetEvent('karma-scenes:remove', function(id)
    local src = source
    if limited(src, 'remove', 1) then return end
    if type(id) ~= 'number' then return end
    local scene, ped = scenes[id], GetPlayerPed(src)
    if not scene or ped == 0 then return end
    if scene.bucket ~= GetPlayerRoutingBucket(src) then return end
    if scene.owner ~= ownerOf(src) and not IsPlayerAceAllowed(src, Config.AdminAce) then return notify(src, 'You can only remove your own scenes.') end
    if SceneRules.distance(GetEntityCoords(ped), scene.coords) > Config.RemoveDistance + 0.5 then return notify(src, 'Move closer to that scene.') end
    scenes[id] = nil
    if not save() then scenes[id] = scene; return notify(src, 'Could not save the removal. Please try again.') end
    publish(scene, 'karma-scenes:remove')
    notify(src, 'Scene removed.', 'success')
end)

AddEventHandler('playerDropped', function()
    cooldowns[source], subscribers[source] = nil, nil
end)

CreateThread(function()
    while true do
        Wait(1000)
        for src, bucket in pairs(subscribers) do
            if not GetPlayerName(src) then subscribers[src] = nil
            elseif GetPlayerRoutingBucket(src) ~= bucket then sync(src) end
        end
        local expired = {}
        for id, scene in pairs(scenes) do
            if scene.expiresAt > 0 and scene.expiresAt <= os.time() then
                expired[#expired + 1] = scene
                scenes[id] = nil
            end
        end
        if #expired > 0 then
            if save() then
                for _, scene in ipairs(expired) do publish(scene, 'karma-scenes:remove') end
            else
                for _, scene in ipairs(expired) do scenes[scene.id] = scene end
            end
        end
    end
end)
