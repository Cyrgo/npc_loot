return {
    -- General settings
    useTarget = true, -- true = ox_target, false = manual key presses
    debugMode = true, -- Enable debug prints and commands
    antiExploitLogging = false, -- Log potential exploits to console
    
    -- Search reward settings (for body searching)
    searchCashChance = 60, -- Chance to find cash when searching bodies
    minSearchCash = 10,
    maxSearchCash = 75,
    
    -- Animation settings
    animations = {
        search = {
            dict = 'amb@medic@standing@kneel@base',
            anim = 'base'
        }
    }
}