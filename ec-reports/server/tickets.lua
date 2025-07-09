Tickets = {}
ActiveTickets = {}
LastTicketId = 0

-- Initialize database tables
CreateThread(function()
    Wait(1000) -- Wait for framework to initialize
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ec_reports (
            id INT AUTO_INCREMENT PRIMARY KEY,
            ticket_id VARCHAR(16) NOT NULL,
            player_id VARCHAR(60) NOT NULL,
            player_name VARCHAR(255) NOT NULL,
            category VARCHAR(50) NOT NULL,
            subject VARCHAR(255) NOT NULL,
            description TEXT NOT NULL,
            priority VARCHAR(20) DEFAULT 'medium',
            status VARCHAR(20) DEFAULT 'open',
            assigned_to VARCHAR(60) DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ec_report_responses (
            id INT AUTO_INCREMENT PRIMARY KEY,
            ticket_id VARCHAR(16) NOT NULL,
            responder_id VARCHAR(60) NOT NULL,
            responder_name VARCHAR(255) NOT NULL,
            message TEXT NOT NULL,
            is_admin BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    -- Load active tickets from database
    MySQL.query('SELECT * FROM ec_reports WHERE status != "closed" ORDER BY created_at DESC', {}, function(results)
        if results and #results > 0 then
            for _, ticket in ipairs(results) do
                ActiveTickets[ticket.ticket_id] = ticket
                if tonumber(ticket.ticket_id:sub(2)) > LastTicketId then
                    LastTicketId = tonumber(ticket.ticket_id:sub(2))
                end
            end
            print('EC Reports: Loaded ' .. #results .. ' active tickets')
        end
    end)
end)

-- Generate a new ticket ID
function GenerateTicketId()
    LastTicketId = LastTicketId + 1
    return 'T' .. string.format('%05d', LastTicketId)
end

-- Create a new ticket
Tickets.CreateTicket = function(source, data)
    local playerId = Framework.GetPlayerIdentifier(source)
    local playerName = Framework.GetPlayerName(source)
    
    if not playerId then return false, 'Player identifier not found' end
    
    local ticketId = GenerateTicketId()
    local ticket = {
        ticket_id = ticketId,
        player_id = playerId,
        player_name = playerName,
        category = data.category,
        subject = data.subject,
        description = data.description,
        priority = 'medium',
        status = 'open',
        created_at = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    MySQL.insert('INSERT INTO ec_reports (ticket_id, player_id, player_name, category, subject, description) VALUES (?, ?, ?, ?, ?, ?)',
        {ticketId, playerId, playerName, data.category, data.subject, data.description},
        function(id)
            if id then
                ActiveTickets[ticketId] = ticket
                TriggerClientEvent('ec_reports:ticketCreated', source, ticketId)
                
                -- Notify all admins
                Tickets.NotifyAdmins('New report submitted: ' .. data.subject, ticketId)
            end
        end
    )
    
    return true, ticketId
end

-- Get ticket by ID
Tickets.GetTicket = function(ticketId)
    if ActiveTickets[ticketId] then
        return ActiveTickets[ticketId]
    end
    
    -- If not in memory, try to fetch from database
    local result = MySQL.query.await('SELECT * FROM ec_reports WHERE ticket_id = ?', {ticketId})
    if result and #result > 0 then
        return result[1]
    end
    
    return nil
end

-- Get all responses for a ticket
Tickets.GetTicketResponses = function(ticketId)
    local result = MySQL.query.await('SELECT * FROM ec_report_responses WHERE ticket_id = ? ORDER BY created_at ASC', {ticketId})
    return result or {}
end

-- Add response to a ticket
Tickets.AddResponse = function(source, ticketId, message, isAdmin)
    local playerId = Framework.GetPlayerIdentifier(source)
    local playerName = Framework.GetPlayerName(source)
    
    if not playerId then return false, 'Player identifier not found' end
    
    local ticket = Tickets.GetTicket(ticketId)
    if not ticket then return false, 'Ticket not found' end
    
    MySQL.insert('INSERT INTO ec_report_responses (ticket_id, responder_id, responder_name, message, is_admin) VALUES (?, ?, ?, ?, ?)',
        {ticketId, playerId, playerName, message, isAdmin},
        function(id)
            if id then
                -- Update ticket's updated_at timestamp
                MySQL.update('UPDATE ec_reports SET updated_at = CURRENT_TIMESTAMP WHERE ticket_id = ?', {ticketId})
                
                -- Notify the ticket owner if admin responded
                if isAdmin and ticket.player_id ~= playerId then
                    local targetSource = Tickets.GetSourceFromIdentifier(ticket.player_id)
                    if targetSource then
                        TriggerClientEvent('ec_reports:responseAdded', targetSource, ticketId, {
                            responder_name = playerName,
                            message = message,
                            is_admin = isAdmin,
                            created_at = os.date('%Y-%m-%d %H:%M:%S')
                        })
                    end
                end
                
                -- Notify admins if player responded
                if not isAdmin then
                    Tickets.NotifyAdmins('New response on ticket ' .. ticketId, ticketId)
                end
            end
        end
    )
    
    return true
end

-- Update ticket status
Tickets.UpdateStatus = function(ticketId, status, source)
    local ticket = Tickets.GetTicket(ticketId)
    if not ticket then return false, 'Ticket not found' end
    
    MySQL.update('UPDATE ec_reports SET status = ? WHERE ticket_id = ?', {status, ticketId}, function(rowsChanged)
        if rowsChanged > 0 then
            if ActiveTickets[ticketId] then
                ActiveTickets[ticketId].status = status
            end
            
            -- If closed, remove from active tickets
            if status == 'closed' then
                ActiveTickets[ticketId] = nil
            end
            
            -- Notify the ticket owner
            local targetSource = Tickets.GetSourceFromIdentifier(ticket.player_id)
            if targetSource then
                TriggerClientEvent('ec_reports:ticketUpdated', targetSource, ticketId, {status = status})
            end
            
            -- Notify admins
            local adminName = Framework.GetPlayerName(source)
            Tickets.NotifyAdmins('Ticket ' .. ticketId .. ' marked as ' .. status .. ' by ' .. adminName, ticketId)
        end
    end)
    
    return true
end

-- Assign ticket to admin
Tickets.AssignTicket = function(ticketId, adminId, adminName)
    local ticket = Tickets.GetTicket(ticketId)
    if not ticket then return false, 'Ticket not found' end
    
    MySQL.update('UPDATE ec_reports SET assigned_to = ? WHERE ticket_id = ?', {adminId, ticketId}, function(rowsChanged)
        if rowsChanged > 0 then
            if ActiveTickets[ticketId] then
                ActiveTickets[ticketId].assigned_to = adminId
            end
            
            -- Notify the ticket owner
            local targetSource = Tickets.GetSourceFromIdentifier(ticket.player_id)
            if targetSource then
                TriggerClientEvent('ec_reports:ticketUpdated', targetSource, ticketId, {assigned_to = adminId})
            end
            
            -- Notify admins
            Tickets.NotifyAdmins('Ticket ' .. ticketId .. ' assigned to ' .. adminName, ticketId)
        end
    end)
    
    return true
end

-- Update ticket priority
Tickets.UpdatePriority = function(ticketId, priority, source)
    local ticket = Tickets.GetTicket(ticketId)
    if not ticket then return false, 'Ticket not found' end
    
    MySQL.update('UPDATE ec_reports SET priority = ? WHERE ticket_id = ?', {priority, ticketId}, function(rowsChanged)
        if rowsChanged > 0 then
            if ActiveTickets[ticketId] then
                ActiveTickets[ticketId].priority = priority
            end
            
            -- Notify admins
            local adminName = Framework.GetPlayerName(source)
            Tickets.NotifyAdmins('Ticket ' .. ticketId .. ' priority set to ' .. priority .. ' by ' .. adminName, ticketId)
        end
    end)
    
    return true
end

-- Get all tickets for a player
Tickets.GetPlayerTickets = function(playerId)
    local result = MySQL.query.await('SELECT * FROM ec_reports WHERE player_id = ? ORDER BY created_at DESC', {playerId})
    return result or {}
end

-- Get all active tickets
Tickets.GetAllActiveTickets = function()
    local tickets = {}
    for _, ticket in pairs(ActiveTickets) do
        table.insert(tickets, ticket)
    end
    return tickets
end

-- Get player source from identifier
Tickets.GetSourceFromIdentifier = function(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local playerIdentifier = Framework.GetPlayerIdentifier(tonumber(playerId))
        if playerIdentifier == identifier then
            return tonumber(playerId)
        end
    end
    return nil
end

-- Notify all online admins
Tickets.NotifyAdmins = function(message, ticketId)
    for _, playerId in ipairs(GetPlayers()) do
        if Framework.IsAdmin(tonumber(playerId)) then
            TriggerClientEvent('ec_reports:adminNotification', tonumber(playerId), message, ticketId)
        end
    end
end
