
local playerCooldowns = {}

-- Check if player is admin
RegisterNetEvent('ec_reports:checkAdminStatus')
AddEventHandler('ec_reports:checkAdminStatus', function()
    local source = source
    local isAdmin = Framework.IsAdmin(source)
    TriggerClientEvent('ec_reports:setAdminStatus', source, isAdmin)
end)

-- Get player name
RegisterNetEvent('ec_reports:getPlayerName')
AddEventHandler('ec_reports:getPlayerName', function()
    local source = source
    local playerName = Framework.GetPlayerName(source)
    TriggerClientEvent('ec_reports:setPlayerName', source, playerName)
end)

-- Register the report command
RegisterCommand(Config.CommandName, function(source, args, rawCommand)
    TriggerClientEvent('ec_reports:openReportMenu', source)
end, false)

-- Create a new report
RegisterNetEvent('ec_reports:submitReport')
AddEventHandler('ec_reports:submitReport', function(data)
    local source = source
    local playerId = Framework.GetPlayerIdentifier(source)
    
    -- Check cooldown
    if playerCooldowns[playerId] and (os.time() - playerCooldowns[playerId]) < Config.ReportCooldown then
        local timeLeft = Config.ReportCooldown - (os.time() - playerCooldowns[playerId])
        TriggerClientEvent('ec_reports:notification', source, 'Please wait ' .. timeLeft .. ' seconds before submitting another report.', 'error')
        return
    end
    
    -- Validate data
    if not data.category or not data.subject or not data.description then
        TriggerClientEvent('ec_reports:notification', source, 'Please fill in all required fields.', 'error')
        return
    end
    
    if string.len(data.subject) < 3 then
        TriggerClientEvent('ec_reports:notification', source, 'Subject is too short.', 'error')
        return
    end
    
    if string.len(data.description) < 10 then
        TriggerClientEvent('ec_reports:notification', source, 'Description is too short. Please provide more details.', 'error')
        return
    end
    
    -- Create the ticket
    local success, result = Tickets.CreateTicket(source, data)
    
    if success then
        -- Set cooldown
        playerCooldowns[playerId] = os.time()
        
        -- Notify player
        TriggerClientEvent('ec_reports:notification', source, 'Your report has been submitted. Ticket ID: ' .. result, 'success')
        
        -- Send to Discord webhook if enabled
        if Config.Notifications.useDiscordWebhook and Config.Notifications.discordWebhook ~= '' then
            local playerName = Framework.GetPlayerName(source)
            local message = {
                embeds = {
                    {
                        title = "New Report: " .. data.subject,
                        description = data.description,
                        color = 9442302, -- Purple color
                        fields = {
                            {name = "Category", value = data.category, inline = true},
                            {name = "Ticket ID", value = result, inline = true},
                            {name = "Player", value = playerName, inline = true}
                        },
                        footer = {
                            text = "EC Reports • " .. os.date("%Y-%m-%d %H:%M:%S")
                        }
                    }
                }
            }
            
            PerformHttpRequest(Config.Notifications.discordWebhook, function(err, text, headers) end, 'POST', json.encode(message), { ['Content-Type'] = 'application/json' })
        end
    else
        TriggerClientEvent('ec_reports:notification', source, 'Failed to submit report: ' .. result, 'error')
    end
end)

-- Get player's tickets
RegisterNetEvent('ec_reports:getMyTickets')
AddEventHandler('ec_reports:getMyTickets', function()
    local source = source
    local playerId = Framework.GetPlayerIdentifier(source)
    
    if not playerId then 
        TriggerClientEvent('ec_reports:notification', source, 'Could not identify your player.', 'error')
        return 
    end
    
    local tickets = Tickets.GetPlayerTickets(playerId)
    TriggerClientEvent('ec_reports:receiveMyTickets', source, tickets)
end)

-- Get ticket details
RegisterNetEvent('ec_reports:getTicketDetails')
AddEventHandler('ec_reports:getTicketDetails', function(ticketId)
    local source = source
    local playerId = Framework.GetPlayerIdentifier(source)
    
    if not playerId then 
        TriggerClientEvent('ec_reports:notification', source, 'Could not identify your player.', 'error')
        return 
    end
    
    local ticket = Tickets.GetTicket(ticketId)
    if not ticket then
        TriggerClientEvent('ec_reports:notification', source, 'Ticket not found.', 'error')
        return
    end
    
    -- Check if player is the ticket owner or an admin
    if ticket.player_id ~= playerId and not Framework.IsAdmin(source) then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to view this ticket.', 'error')
        return
    end
    
    local responses = Tickets.GetTicketResponses(ticketId)
    TriggerClientEvent('ec_reports:receiveTicketDetails', source, ticket, responses)
end)

-- Add response to ticket
RegisterNetEvent('ec_reports:addResponse')
AddEventHandler('ec_reports:addResponse', function(ticketId, message)
    local source = source
    local playerId = Framework.GetPlayerIdentifier(source)
    
    if not playerId then 
        TriggerClientEvent('ec_reports:notification', source, 'Could not identify your player.', 'error')
        return 
    end
    
    local ticket = Tickets.GetTicket(ticketId)
    if not ticket then
        TriggerClientEvent('ec_reports:notification', source, 'Ticket not found.', 'error')
        return
    end
    
    -- Check if player is the ticket owner or an admin
    local isAdmin = Framework.IsAdmin(source)
    if ticket.player_id ~= playerId and not isAdmin then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to respond to this ticket.', 'error')
        return
    end
    
    -- Validate message
    if not message or message:len() < 1 then
        TriggerClientEvent('ec_reports:notification', source, 'Response cannot be empty.', 'error')
        return
    end
    
    -- Add the response
    local success = Tickets.AddResponse(source, ticketId, message, isAdmin)
    
    if success then
        TriggerClientEvent('ec_reports:notification', source, 'Response added successfully.', 'success')
        
        -- Refresh ticket details for the player
        local responses = Tickets.GetTicketResponses(ticketId)
        TriggerClientEvent('ec_reports:receiveTicketDetails', source, ticket, responses)
        
        -- If admin responded, update ticket status to in-progress if it was open
        if isAdmin and ticket.status == 'open' then
            Tickets.UpdateStatus(ticketId, 'in-progress', source)
        end
    else
        TriggerClientEvent('ec_reports:notification', source, 'Failed to add response.', 'error')
    end
end)

-- Update ticket status (admin only)
RegisterNetEvent('ec_reports:updateTicketStatus')
AddEventHandler('ec_reports:updateTicketStatus', function(ticketId, status)
    local source = source
    
    -- Check if player is an admin
    if not Framework.IsAdmin(source) then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to update ticket status.', 'error')
        return
    end
    
    -- Validate status
    if not status or (status ~= 'open' and status ~= 'in-progress' and status ~= 'closed') then
        TriggerClientEvent('ec_reports:notification', source, 'Invalid status.', 'error')
        return
    end
    
    local success = Tickets.UpdateStatus(ticketId, status, source)
    
    if success then
        TriggerClientEvent('ec_reports:notification', source, 'Ticket status updated successfully.', 'success')
    else
        TriggerClientEvent('ec_reports:notification', source, 'Failed to update ticket status.', 'error')
    end
end)

-- Assign ticket to admin (admin only)
RegisterNetEvent('ec_reports:assignTicket')
AddEventHandler('ec_reports:assignTicket', function(ticketId)
    local source = source
    
    -- Check if player is an admin
    if not Framework.IsAdmin(source) then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to assign tickets.', 'error')
        return
    end
    
    local adminId = Framework.GetPlayerIdentifier(source)
    local adminName = Framework.GetPlayerName(source)
    
    local success = Tickets.AssignTicket(ticketId, adminId, adminName)
    
    if success then
        TriggerClientEvent('ec_reports:notification', source, 'Ticket assigned to you successfully.', 'success')
        
        -- Also update status to in-progress if it was open
        local ticket = Tickets.GetTicket(ticketId)
        if ticket and ticket.status == 'open' then
            Tickets.UpdateStatus(ticketId, 'in-progress', source)
        end
    else
        TriggerClientEvent('ec_reports:notification', source, 'Failed to assign ticket.', 'error')
    end
end)

-- Update ticket priority (admin only)
RegisterNetEvent('ec_reports:updateTicketPriority')
AddEventHandler('ec_reports:updateTicketPriority', function(ticketId, priority)
    local source = source
    
    -- Check if player is an admin
    if not Framework.IsAdmin(source) then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to update ticket priority.', 'error')
        return
    end
    
    -- Validate priority
    local validPriority = false
    for _, p in ipairs(Config.Priorities) do
        if p.value == priority then
            validPriority = true
            break
        end
    end
    
    if not validPriority then
        TriggerClientEvent('ec_reports:notification', source, 'Invalid priority.', 'error')
        return
    end
    
    local success = Tickets.UpdatePriority(ticketId, priority, source)
    
    if success then
        TriggerClientEvent('ec_reports:notification', source, 'Ticket priority updated successfully.', 'success')
    else
        TriggerClientEvent('ec_reports:notification', source, 'Failed to update ticket priority.', 'error')
    end
end)

-- Get all active tickets (admin only)
RegisterNetEvent('ec_reports:getAllActiveTickets')
AddEventHandler('ec_reports:getAllActiveTickets', function()
    local source = source
    
    -- Check if player is an admin
    if not Framework.IsAdmin(source) then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to view all tickets.', 'error')
        return
    end
    
    local tickets = Tickets.GetAllActiveTickets()
    TriggerClientEvent('ec_reports:receiveAllActiveTickets', source, tickets)
end)

-- Get admin dashboard stats
RegisterNetEvent('ec_reports:getAdminStats')
AddEventHandler('ec_reports:getAdminStats', function()
    local source = source
    
    -- Check if player is an admin
    if not Framework.IsAdmin(source) then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to view admin stats.', 'error')
        return
    end
    
    -- Get current date in SQL format
    local today = os.date('%Y-%m-%d')
    
    -- Get stats from database
    local openCount = MySQL.query.await('SELECT COUNT(*) as count FROM ec_reports WHERE status = "open"')
    local inProgressCount = MySQL.query.await('SELECT COUNT(*) as count FROM ec_reports WHERE status = "in-progress"')
    local urgentCount = MySQL.query.await('SELECT COUNT(*) as count FROM ec_reports WHERE priority = "urgent" AND status != "closed"')
    local closedTodayCount = MySQL.query.await('SELECT COUNT(*) as count FROM ec_reports WHERE status = "closed" AND DATE(updated_at) = ?', {today})
    
    local stats = {
        open = openCount[1].count,
        inProgress = inProgressCount[1].count,
        urgent = urgentCount[1].count,
        closedToday = closedTodayCount[1].count
    }
    
    TriggerClientEvent('ec_reports:updateAdminStats', source, stats)
end)

-- Extract location from bug report and teleport admin
RegisterNetEvent('ec_reports:getTeleportLocation')
AddEventHandler('ec_reports:getTeleportLocation', function(ticketId)
    local source = source
    
    -- Check if player is an admin
    if not Framework.IsAdmin(source) then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to teleport.', 'error')
        return
    end
    
    local ticket = Tickets.GetTicket(ticketId)
    if not ticket then
        TriggerClientEvent('ec_reports:notification', source, 'Ticket not found.', 'error')
        return
    end
    
    -- Try to extract location from description
    local locationStr = string.match(ticket.description, "Location:%s*([^\n]+)")
    if not locationStr then
        TriggerClientEvent('ec_reports:notification', source, 'No location found in this report.', 'error')
        return
    end
    
    -- Try to parse coordinates
    local x, y, z = string.match(locationStr, "(-?%d+%.?%d*),?%s*(-?%d+%.?%d*),?%s*(-?%d+%.?%d*)")
    
    if x and y and z then
        -- Found coordinates in the format "x, y, z"
        TriggerClientEvent('ec_reports:setTeleportLocation', source, {
            x = tonumber(x),
            y = tonumber(y),
            z = tonumber(z)
        })
    else
        -- If no coordinates found, check if there's a player name or ID
        local playerId = string.match(locationStr, "(%d+)")
        if playerId then
            local targetSource = tonumber(playerId)
            if targetSource and GetPlayerPing(targetSource) > 0 then
                -- Get player's position
                TriggerClientEvent('ec_reports:getPlayerPosition', targetSource, source)
                return
            end
        end
        
        TriggerClientEvent('ec_reports:notification', source, 'Could not parse location from report.', 'error')
    end
end)

-- Get player position for teleporting
RegisterNetEvent('ec_reports:returnPlayerPosition')
AddEventHandler('ec_reports:returnPlayerPosition', function(adminSource, position)
    if position then
        TriggerClientEvent('ec_reports:setTeleportLocation', adminSource, position)
    else
        TriggerClientEvent('ec_reports:notification', adminSource, 'Failed to get player position.', 'error')
    end
end)

-- Admin command to force close UI for all players
RegisterCommand('fixreportall', function(source, args, rawCommand)
    -- Check if player is an admin
    if not Framework.IsAdmin(source) then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to use this command.', 'error')
        return
    end
    
    -- Force close UI for all players
    TriggerClientEvent('ec_reports:forceClose', -1)
    TriggerClientEvent('ec_reports:notification', source, 'Report UI has been force-closed for all players.', 'success')
end, false)

-- Admin command to view ticket by ID
RegisterCommand('viewticket', function(source, args, rawCommand)
    -- Check if player is an admin
    if not Framework.IsAdmin(source) then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to use this command.', 'error')
        return
    end
    
    if not args[1] then
        TriggerClientEvent('ec_reports:notification', source, 'Usage: /viewticket [ticketId]', 'error')
        return
    end
    
    local ticketId = args[1]
    local ticket = Tickets.GetTicket(ticketId)
    
    if not ticket then
        TriggerClientEvent('ec_reports:notification', source, 'Ticket not found.', 'error')
        return
    end
    
    local responses = Tickets.GetTicketResponses(ticketId)
    TriggerClientEvent('ec_reports:receiveTicketDetails', source, ticket, responses)
    TriggerClientEvent('ec_reports:openReportMenu', source)
end, false)

-- Admin command to close a ticket by ID
RegisterCommand('closeticket', function(source, args, rawCommand)
    -- Check if player is an admin
    if not Framework.IsAdmin(source) then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to use this command.', 'error')
        return
    end
    
    if not args[1] then
        TriggerClientEvent('ec_reports:notification', source, 'Usage: /closeticket [ticketId]', 'error')
        return
    end
    
    local ticketId = args[1]
    local success = Tickets.UpdateStatus(ticketId, 'closed', source)
    
    if success then
        TriggerClientEvent('ec_reports:notification', source, 'Ticket #' .. ticketId .. ' has been closed.', 'success')
    else
        TriggerClientEvent('ec_reports:notification', source, 'Failed to close ticket. Ticket may not exist.', 'error')
    end
end, false)

-- Admin command to get report statistics
RegisterCommand('reportstats', function(source, args, rawCommand)
    -- Check if player is an admin
    if not Framework.IsAdmin(source) then
        TriggerClientEvent('ec_reports:notification', source, 'You do not have permission to use this command.', 'error')
        return
    end
    
    -- Get current date in SQL format
    local today = os.date('%Y-%m-%d')
    
    -- Get stats from database
    local openCount = MySQL.query.await('SELECT COUNT(*) as count FROM ec_reports WHERE status = "open"')
    local inProgressCount = MySQL.query.await('SELECT COUNT(*) as count FROM ec_reports WHERE status = "in-progress"')
    local urgentCount = MySQL.query.await('SELECT COUNT(*) as count FROM ec_reports WHERE priority = "urgent" AND status != "closed"')
    local closedTodayCount = MySQL.query.await('SELECT COUNT(*) as count FROM ec_reports WHERE status = "closed" AND DATE(updated_at) = ?', {today})
    local totalCount = MySQL.query.await('SELECT COUNT(*) as count FROM ec_reports')
    
    -- Send stats to player
    TriggerClientEvent('ec_reports:notification', source, 'Report Statistics:', 'info')
    TriggerClientEvent('ec_reports:notification', source, 'Open: ' .. openCount[1].count .. ' | In Progress: ' .. inProgressCount[1].count, 'info')
    TriggerClientEvent('ec_reports:notification', source, 'Urgent: ' .. urgentCount[1].count .. ' | Closed Today: ' .. closedTodayCount[1].count, 'info')
    TriggerClientEvent('ec_reports:notification', source, 'Total Reports: ' .. totalCount[1].count, 'info')
end, false)

-- Auto-close abandoned tickets
CreateThread(function()
    while true do
        Wait(3600000) -- Check every hour
        
        if Config.CloseAfterDays > 0 then
            -- Calculate date threshold
            local daysAgo = os.date('%Y-%m-%d', os.time() - (Config.CloseAfterDays * 86400))
            
            -- Find abandoned tickets
            local abandonedTickets = MySQL.query.await('SELECT ticket_id FROM ec_reports WHERE status != "closed" AND DATE(updated_at) <= ?', {daysAgo})
            
            if abandonedTickets and #abandonedTickets > 0 then
                print('EC Reports: Auto-closing ' .. #abandonedTickets .. ' abandoned tickets')
                
                for _, ticket in ipairs(abandonedTickets) do
                    Tickets.UpdateStatus(ticket.ticket_id, 'closed', 0) -- 0 as source means system
                    
                    -- Add system response
                    MySQL.insert('INSERT INTO ec_report_responses (ticket_id, responder_id, responder_name, message, is_admin) VALUES (?, ?, ?, ?, ?)',
                        {ticket.ticket_id, 'system', 'System', 'This ticket has been automatically closed due to ' .. Config.CloseAfterDays .. ' days of inactivity.', true}
                    )
                end
            end
        end
    end
end)

-- Player disconnected, clean up cooldowns
AddEventHandler('playerDropped', function()
    local source = source
    local playerId = Framework.GetPlayerIdentifier(source)
    
    if playerId and playerCooldowns[playerId] then
        playerCooldowns[playerId] = nil
    end
end)

-- Error handler for NUI errors
RegisterNetEvent('ec_reports:reportNuiError')
AddEventHandler('ec_reports:reportNuiError', function(errorData)
    local source = source
    local playerName = Framework.GetPlayerName(source)
    
    print('EC Reports: NUI Error from ' .. playerName .. ' (' .. source .. '): ' .. json.encode(errorData))
    
    -- Log to Discord if webhook is configured
    if Config.Notifications.useDiscordWebhook and Config.Notifications.discordWebhook ~= '' then
        local message = {
            embeds = {
                {
                    title = "EC Reports: NUI Error",
                    description = "An error occurred in the NUI interface",
                    color = 15158332, -- Red color
                    fields = {
                        {name = "Player", value = playerName .. ' (' .. source .. ')', inline = true},
                        {name = "Error", value = errorData.message or "Unknown error", inline = false},
                        {name = "Stack", value = errorData.stack or "No stack trace", inline = false}
                    },
                    footer = {
                        text = "EC Reports • " .. os.date("%Y-%m-%d %H:%M:%S")
                    }
                }
            }
        }
        
        PerformHttpRequest(Config.Notifications.discordWebhook, function(err, text, headers) end, 'POST', json.encode(message), { ['Content-Type'] = 'application/json' })
    end
end)

-- Print startup message
CreateThread(function()
    Wait(1000)
    print('┌─────────────────────────────────────────────────┐')
    print('│                                                 │')
    print('│               EC Reports Started                │')
    print('│                                                 │')
    print('│              Advanced Report system             │')
    print('│                                                 │')
    print('└─────────────────────────────────────────────────┘')
end)
