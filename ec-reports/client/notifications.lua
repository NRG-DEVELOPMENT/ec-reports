-- Show notification
function ShowNotification(message, type)
    if not message then return end
    
    type = type or 'info'
    
    SendNUIMessage({
        action = 'showNotification',
        message = message,
        type = type
    })
end

-- Register export
exports('ShowNotification', ShowNotification)

-- Event handler for notifications
RegisterNetEvent('ec_reports:notification')
AddEventHandler('ec_reports:notification', function(message, type)
    ShowNotification(message, type)
end)
