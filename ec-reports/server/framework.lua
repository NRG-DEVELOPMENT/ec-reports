-- File: server/framework.lua

Framework = {}
Framework.Type = nil
Framework.PlayerData = {}

-- Detect and initialize the framework
CreateThread(function()
    if GetResourceState('es_extended') == 'started' then
        Framework.Type = 'ESX'
        Framework.Core = exports['es_extended']:getSharedObject()
        print('EC Reports: ESX framework detected')
    elseif GetResourceState('qb-core') == 'started' then
        Framework.Type = 'QBCore'
        Framework.Core = exports['qb-core']:GetCoreObject()
        print('EC Reports: QBCore framework detected')
    else
        print('EC Reports: No supported framework detected. Some features may not work.')
    end
end)

-- Get player data regardless of framework
Framework.GetPlayer = function(source)
    if Framework.Type == 'ESX' then
        return Framework.Core.GetPlayerFromId(source)
    elseif Framework.Type == 'QBCore' then
        return Framework.Core.Functions.GetPlayer(source)
    end
    return nil
end

-- Check if player has admin permissions using ACE
Framework.IsAdmin = function(source)
    if not source then return false end
    
    -- First check ACE permissions (this will work with server.cfg setup)
    if IsPlayerAceAllowed(source, "command.ec_reports") then
        return true
    end
    
    -- Fallback to framework-specific checks if ACE check fails
    if Framework.Type == 'ESX' then
        local xPlayer = Framework.Core.GetPlayerFromId(source)
        if xPlayer then
            local group = xPlayer.getGroup()
            for _, adminGroup in ipairs(Config.AdminGroups.esx) do
                if group == adminGroup then
                    return true
                end
            end
        end
    elseif Framework.Type == 'QBCore' then
        local Player = Framework.Core.Functions.GetPlayer(source)
        if Player then
            local permission = Player.PlayerData.permission
            for _, adminPerm in ipairs(Config.AdminGroups.qbcore) do
                if permission == adminPerm then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Get player name
Framework.GetPlayerName = function(source)
    if Framework.Type == 'ESX' then
        local xPlayer = Framework.Core.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.getName()
        end
    elseif Framework.Type == 'QBCore' then
        local Player = Framework.Core.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        end
    end
    
    return GetPlayerName(source) or 'Unknown'
end

-- Get player identifier
Framework.GetPlayerIdentifier = function(source)
    if Framework.Type == 'ESX' then
        local xPlayer = Framework.Core.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.identifier
        end
    elseif Framework.Type == 'QBCore' then
        local Player = Framework.Core.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.citizenid
        end
    end
    
    for _, v in pairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            return v
        end
    end
    
    return nil
end
