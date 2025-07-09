Config = {}

-- General settings
Config.CommandName = 'report'  -- Command to open the report menu
Config.ReportCooldown = 120    -- Seconds between reports (prevent spam)
Config.CloseAfterDays = 7      -- Auto-close tickets after X days of inactivity

-- Report categories
Config.Categories = {
    {label = 'Game Bug', value = 'bug', icon = 'bug'},
    {label = 'Player Report', value = 'player', icon = 'user'},
    {label = 'Server Issue', value = 'server', icon = 'server'},
    {label = 'Question', value = 'question', icon = 'question'},
    {label = 'Other', value = 'other', icon = 'ellipsis-h'}
}

-- Priority levels
Config.Priorities = {
    {label = 'Low', value = 'low', color = '#28a745'},
    {label = 'Medium', value = 'medium', color = '#ffc107'},
    {label = 'High', value = 'high', color = '#fd7e14'},
    {label = 'Urgent', value = 'urgent', color = '#dc3545'}
}

-- Admin settings
Config.AdminGroups = {
    -- ESX groups that can access admin features
    esx = {'admin', 'superadmin', 'mod', 'moderator'},
    
    -- QBCore permissions that can access admin features
    qbcore = {'admin', 'god', 'mod'},
    
    -- ACE permission that grants admin access
    ace = 'command.ec_reports'
}

-- Notification settings
Config.Notifications = {
    useSound = true,           -- Play sound for new reports
    soundFile = 'notification.ogg',
    useDiscordWebhook = false, -- Send reports to Discord
    discordWebhook = '',       -- Discord webhook URL
}

-- UI settings
Config.UI = {
    theme = 'dark',            -- 'dark' or 'light'
    accentColor = '#8A2BE2',   -- Purple accent color
    fontSize = 'medium',       -- 'small', 'medium', or 'large'
}
