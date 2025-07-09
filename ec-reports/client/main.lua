
local isReportMenuOpen = false
local playerTickets = {}
local activeTicket = nil
local isAdmin = false
local playerName = nil
local lastTeleportCoords = nil

-- Check if player is admin on resource start
CreateThread(function()
    Wait(1000) -- Wait for framework to initialize
    TriggerServerEvent('ec_reports:checkAdminStatus')
    
    -- Get player name
    TriggerServerEvent('ec_reports:getPlayerName')
end)

-- Set admin status
RegisterNetEvent('ec_reports:setAdminStatus')
AddEventHandler('ec_reports:setAdminStatus', function(status)
    isAdmin = status
    print('EC Reports: Admin status set to ' .. tostring(status))
end)

-- Set player name
RegisterNetEvent('ec_reports:setPlayerName')
AddEventHandler('ec_reports:setPlayerName', function(name)
    playerName = name
end)

-- Force close UI function with debug info
function ForceCloseUI()
    print("EC Reports: ForceCloseUI called - Releasing NUI focus")
    isReportMenuOpen = false
    
    -- Send close message to NUI
    SendNUIMessage({
        action = 'forceClose'
    })
    
    -- Release focus with multiple attempts to ensure it works
    SetNuiFocus(false, false)
    
    -- Double check after short delays
    Citizen.SetTimeout(100, function() SetNuiFocus(false, false) end)
    Citizen.SetTimeout(500, function() SetNuiFocus(false, false) end)
end
-- Register a keybind to close the UI (ESC)
RegisterKeyMapping('closereportui', 'Close Report UI', 'keyboard', 'ESCAPE')

-- Command to close the UI
RegisterCommand('closereportui', function()
    if isReportMenuOpen then
        ForceCloseUI()
    end
end, false)

-- Emergency command to fix stuck UI
RegisterCommand('fixreport', function()
    print("EC Reports: Emergency UI fix triggered")
    ForceCloseUI()
    TriggerEvent('ec_reports:notification', 'UI focus has been reset', 'info')
end, false)

-- Resource stop handler
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and isReportMenuOpen then
        print("EC Reports: Resource stopping - Releasing NUI focus")
        SetNuiFocus(false, false)
    end
end)

-- Open report menu
RegisterNetEvent('ec_reports:openReportMenu')
AddEventHandler('ec_reports:openReportMenu', function()
    -- If already open, close it first
    if isReportMenuOpen then
        ForceCloseUI()
        Wait(500) -- Wait a moment before reopening
    end
    
    isReportMenuOpen = true
    
    -- Request player's tickets
    TriggerServerEvent('ec_reports:getMyTickets')
    
    -- If admin, also get all active tickets and stats
    if isAdmin then
        TriggerServerEvent('ec_reports:getAllActiveTickets')
        TriggerServerEvent('ec_reports:getAdminStats')
    end
    
    -- Open NUI with safety timeout
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu',
        isAdmin = isAdmin,
        playerName = playerName,
        categories = Config.Categories,
        priorities = Config.Priorities,
        theme = Config.UI.theme,
        accentColor = Config.UI.accentColor,
        fontSize = Config.UI.fontSize
    })
    
    -- Safety timeout
    Citizen.SetTimeout(300000, function() -- 5 minutes
        if isReportMenuOpen then
            ForceCloseUI()
            TriggerEvent('ec_reports:notification', 'Report UI was automatically closed after timeout', 'info')
        end
    end)
end)

-- Force close event handler
RegisterNetEvent('ec_reports:forceClose')
AddEventHandler('ec_reports:forceClose', function()
    ForceCloseUI()
end)

-- Close menu NUI callback with error handling
RegisterNUICallback('closeMenu', function(data, cb)
    print("EC Reports: closeMenu NUI callback received")
    ForceCloseUI()
    if cb then cb({success = true}) end
end)

-- Submit a report
RegisterNUICallback('submitReport', function(data, cb)
    TriggerServerEvent('ec_reports:submitReport', {
        category = data.category,
        subject = data.subject,
        description = data.description
    })
    
    if cb then cb({success = true}) end
end)

-- Get player's tickets
RegisterNUICallback('getMyTickets', function(data, cb)
    TriggerServerEvent('ec_reports:getMyTickets')
    if cb then cb({success = true}) end
end)

-- Get all active tickets (admin only)
RegisterNUICallback('getAllActiveTickets', function(data, cb)
    if isAdmin then
        TriggerServerEvent('ec_reports:getAllActiveTickets')
    end
    if cb then cb({success = true}) end
end)

-- Get admin stats (admin only)
RegisterNUICallback('getAdminStats', function(data, cb)
    if isAdmin then
        TriggerServerEvent('ec_reports:getAdminStats')
    end
    if cb then cb({success = true}) end
end)

-- View ticket details
RegisterNUICallback('viewTicket', function(data, cb)
    TriggerServerEvent('ec_reports:getTicketDetails', data.ticketId)
    if cb then cb({success = true}) end
end)

-- Add response to ticket
RegisterNUICallback('addResponse', function(data, cb)
    TriggerServerEvent('ec_reports:addResponse', data.ticketId, data.message)
    if cb then cb({success = true}) end
end)

-- Assign ticket to self (admin only)
RegisterNUICallback('assignTicket', function(data, cb)
    if isAdmin then
        TriggerServerEvent('ec_reports:assignTicket', data.ticketId)
    end
    if cb then cb({success = true}) end
end)

-- Update ticket status (admin only)
RegisterNUICallback('updateTicketStatus', function(data, cb)
    if isAdmin then
        TriggerServerEvent('ec_reports:updateTicketStatus', data.ticketId, data.status)
    end
    if cb then cb({success = true}) end
end)

-- Update ticket priority (admin only)
RegisterNUICallback('updateTicketPriority', function(data, cb)
    if isAdmin then
        TriggerServerEvent('ec_reports:updateTicketPriority', data.ticketId, data.priority)
    end
    if cb then cb({success = true}) end
end)

-- Teleport to location (admin only)
RegisterNUICallback('teleportToLocation', function(data, cb)
    if isAdmin then
        -- Save current location for return
        lastTeleportCoords = GetEntityCoords(PlayerPedId())
        
        -- Request teleport
        TriggerServerEvent('ec_reports:getTeleportLocation', data.ticketId)
    end
    if cb then cb({success = true}) end
end)

-- Return to previous location after teleport
RegisterCommand('returnfromreport', function()
    if isAdmin and lastTeleportCoords then
        SetEntityCoords(PlayerPedId(), lastTeleportCoords.x, lastTeleportCoords.y, lastTeleportCoords.z)
        TriggerEvent('ec_reports:notification', 'Returned to previous location', 'info')
        lastTeleportCoords = nil
    else
        TriggerEvent('ec_reports:notification', 'No previous location to return to', 'error')
    end
end, false)

-- Add a suggestion for the return command
TriggerEvent('chat:addSuggestion', '/returnfromreport', 'Return to your location before teleporting to a report')

-- Error reporting from NUI
RegisterNUICallback('reportError', function(data, cb)
    print("EC Reports: NUI Error: " .. (data.message or "Unknown error"))
    if data.stack then
        print("EC Reports: Stack: " .. data.stack)
    end
    
    if cb then cb({success = true}) end
end)

-- Receive player's tickets
RegisterNetEvent('ec_reports:receiveMyTickets')
AddEventHandler('ec_reports:receiveMyTickets', function(tickets)
    playerTickets = tickets
    
    SendNUIMessage({
        action = 'updateMyTickets',
        tickets = tickets
    })
end)

-- Receive all active tickets (admin only)
RegisterNetEvent('ec_reports:receiveAllActiveTickets')
AddEventHandler('ec_reports:receiveAllActiveTickets', function(tickets)
    if not isAdmin then return end
    
    SendNUIMessage({
        action = 'updateAllTickets',
        tickets = tickets
    })
end)

-- Receive admin stats
RegisterNetEvent('ec_reports:updateAdminStats')
AddEventHandler('ec_reports:updateAdminStats', function(stats)
    if not isAdmin then return end
    
    SendNUIMessage({
        action = 'updateAdminStats',
        stats = stats
    })
end)

-- Receive ticket details
RegisterNetEvent('ec_reports:receiveTicketDetails')
AddEventHandler('ec_reports:receiveTicketDetails', function(ticket, responses)
    activeTicket = ticket
    
    SendNUIMessage({
        action = 'showTicketDetails',
        ticket = ticket,
        responses = responses
    })
end)

-- Notification when ticket is created
RegisterNetEvent('ec_reports:ticketCreated')
AddEventHandler('ec_reports:ticketCreated', function(ticketId)
    SendNUIMessage({
        action = 'ticketCreated',
        ticketId = ticketId
    })
end)

-- Notification when ticket is updated
RegisterNetEvent('ec_reports:ticketUpdated')
AddEventHandler('ec_reports:ticketUpdated', function(ticketId, updates)
    SendNUIMessage({
        action = 'ticketUpdated',
        ticketId = ticketId,
        updates = updates
    })
    
    -- If admin, refresh tickets and stats
    if isAdmin then
        TriggerServerEvent('ec_reports:getAllActiveTickets')
        TriggerServerEvent('ec_reports:getAdminStats')
    end
end)

-- Notification when response is added
RegisterNetEvent('ec_reports:responseAdded')
AddEventHandler('ec_reports:responseAdded', function(ticketId, response)
    -- If we're viewing this ticket, update the UI
    if activeTicket and activeTicket.ticket_id == ticketId then
        SendNUIMessage({
            action = 'newResponse',
            ticketId = ticketId,
            response = response
        })
    end
    
    -- Show notification
    ShowNotification('New response on ticket #' .. ticketId)
end)

-- Admin notification for new reports/responses
RegisterNetEvent('ec_reports:adminNotification')
AddEventHandler('ec_reports:adminNotification', function(message, ticketId)
    if not isAdmin then return end
    
    -- Show notification
    ShowNotification(message, 'info')
    
    -- Play sound if enabled
    if Config.Notifications.useSound then
        SendNUIMessage({
            action = 'playNotificationSound'
        })
    end
    
    -- Refresh admin data
    TriggerServerEvent('ec_reports:getAllActiveTickets')
    TriggerServerEvent('ec_reports:getAdminStats')
end)

-- Handle teleport location response
RegisterNetEvent('ec_reports:setTeleportLocation')
AddEventHandler('ec_reports:setTeleportLocation', function(coords)
    if not isAdmin then return end
    
    if not coords then
        ShowNotification('Could not find a valid location in this report.', 'error')
        return
    end
    
    -- Teleport player
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
    ShowNotification('Teleported to report location. Use /returnfromreport to go back.', 'success')
    
    -- Close UI
    ForceCloseUI()
end)

-- Get player position for teleporting
RegisterNetEvent('ec_reports:getPlayerPosition')
AddEventHandler('ec_reports:getPlayerPosition', function(adminSource)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent('ec_reports:returnPlayerPosition', adminSource, {
        x = coords.x,
        y = coords.y,
        z = coords.z
    })
end)

-- Show notification
function ShowNotification(message, type)
    type = type or 'info'
    
    -- Send to NUI
    SendNUIMessage({
        action = 'showNotification',
        message = message,
        type = type
    })
    
    -- Also show native notification as fallback
    if type == 'error' then
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(true, false)
    end
end

-- Register notification event
RegisterNetEvent('ec_reports:notification')
AddEventHandler('ec_reports:notification', function(message, type)
    ShowNotification(message, type)
end)

-- Register command
RegisterCommand(Config.CommandName, function()
    TriggerEvent('ec_reports:openReportMenu')
end, false)

-- Add command suggestion
TriggerEvent('chat:addSuggestion', '/' .. Config.CommandName, 'Open the report menu to submit or view reports')

-- Initialize when resource starts
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- Check if player is admin
    TriggerServerEvent('ec_reports:checkAdminStatus')
    
    -- Get player name
    TriggerServerEvent('ec_reports:getPlayerName')
    
    print('EC Reports: Client initialized')
end)


CreateThread(function()
    while true do
        Wait(0)
        if isReportMenuOpen then
            -- Check for ESC key (key code 27)
            if IsControlJustReleased(0, 27) or IsDisabledControlJustReleased(0, 27) then
                print("EC Reports: ESC key detected - Closing UI")
                ForceCloseUI()
            end
        else
            -- If UI is not open, we don't need to check every frame
            Wait(500)
        end
    end
end)