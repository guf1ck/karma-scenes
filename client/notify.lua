-- EDIT THIS FUNCTION to use your server's custom notification resource.
-- message: string | notifyType: 'success', 'error', 'inform' | duration: milliseconds
-- Replace the body with your notification export/event, using its documented arguments.
-- Default: automatically use the running framework's configured notifications.
function Config.Notify(message, notifyType, duration)
    notifyType = notifyType or 'inform'
    duration = duration or 4500

    if GetResourceState('qbx_core') == 'started' then
        exports['qbx_core']:Notify(message, notifyType, duration)
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        QBCore.Functions.Notify(message, notifyType == 'inform' and 'primary' or notifyType, duration)
    elseif GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        ESX.ShowNotification(message, notifyType == 'inform' and 'info' or notifyType, duration)
    else
        -- Standalone fallback: GTA's notification feed, never a scene NUI popup.
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, false)
    end
end
