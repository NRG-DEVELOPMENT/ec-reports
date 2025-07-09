-- Handle keyboard shortcuts
CreateThread(function()
    while true do
        Wait(0)
        
        -- ESC key to close UI if it's open
        if isReportMenuOpen and IsControlJustReleased(0, 200) then -- ESC key
            isReportMenuOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({
                action = 'closeMenu'
            })
        end
    end
end)

-- Check admin status when player loads
RegisterNetEvent('ec_reports:checkAdminStatus')
AddEventHandler('ec_reports:checkAdminStatus', function()
    TriggerServerEvent('ec_reports:checkAdminStatus')
end)
