return {
    -- General settings
    useTarget = true, -- true = ox_target, false = manual key presses
    debugMode = true, -- Enable debug prints and commands
    antiExploitLogging = false, -- Log potential exploits to console
    
    -- Search reward settings (for body searching)
    searchCashChance = 60, -- Chance to find cash when searching bodies
    minSearchCash = 10,
    maxSearchCash = 75,
    
    -- Phone buyer NPC settings
    phoneBuyer = {
        enabled = true,
        npc = {
            model = 'ig_g',
            coords = vector4(106.24, -1280.32, 28.24, 120.0),
            scenario = 'WORLD_HUMAN_SMOKING',
        },
        blip = {
            sprite = 459, -- Phone icon
            display = 4,
            scale = 0.7,
            colour = 2, -- Green
            label = 'Phone Buyer'
        },
        phonePrice = {
            min = 100,
            max = 100
        }
    },
    
    -- Animation settings
    animations = {
        search = {
            dict = 'amb@medic@standing@kneel@base',
            anim = 'base'
        }
    }
}