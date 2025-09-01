local config = require 'config'
local QBX = exports.qbx_core

-- Helper functions
local function getRandomSearchReward()
    local rewards = {
        {item = 'money', amount = math.random(config.minSearchCash, config.maxSearchCash), chance = config.searchCashChance},
        {item = 'phone', amount = 1, chance = 15},
        {item = 'id_card', amount = 1, chance = 10},
        {item = 'wallet', amount = 1, chance = 10},
        {item = nil, amount = 0, chance = 15}, -- Nothing found
        -- Add more items as needed
    }
    
    local totalChance = 0
    for _, reward in pairs(rewards) do
        totalChance = totalChance + reward.chance
    end
    
    local randomChance = math.random(totalChance)
    local currentChance = 0
    
    for _, reward in pairs(rewards) do
        currentChance = currentChance + reward.chance
        if randomChance <= currentChance then
            return reward
        end
    end
    
    return rewards[1] -- Fallback
end

-- Simple rate limiting to prevent spam (no persistent tracking like vehicle inventories)
local lastSearchTime = {}
-- Track created NPC body inventories to prevent duplicate searches
local searchedBodies = {}

-- Check if a body has already been searched
lib.callback.register('npc_loot:server:isBodySearched', function(source, coords, model)
    -- Validate parameters
    if not coords or not model or type(coords) ~= 'vector3' or type(model) ~= 'number' or model == 0 then
        return true -- Return true (searched) if invalid data to prevent exploits
    end
    
    local uniqueId = ('%d_%.2f_%.2f_%.2f'):format(model, coords.x, coords.y, coords.z)
    return searchedBodies[uniqueId] == true
end)

-- Handle searching dead NPCs
RegisterNetEvent('npc_loot:server:searchNPC', function(uniqueId, coords, model)
    local src = source
    local player = QBX:GetPlayer(src)
    
    if not player then return end
    
    -- Validate parameters
    if not uniqueId or not coords or not model or 
       type(uniqueId) ~= 'string' or type(coords) ~= 'vector3' or 
       type(model) ~= 'number' or model == 0 then
        if config.antiExploitLogging then
            print(('[npc_loot] Player %s [%d] sent invalid search data'):format(GetPlayerName(src), src))
        end
        return
    end
    
    -- Check if this body has already been searched (prevent multiple loot)
    if searchedBodies[uniqueId] then
        TriggerClientEvent('qbx_core:Notify', src, 'This body has already been searched', 'error')
        return
    end
    
    -- Simple rate limiting (max 1 search every 3 seconds)
    local currentTime = GetGameTimer()
    if lastSearchTime[src] and (currentTime - lastSearchTime[src]) < 3000 then
        if config.antiExploitLogging then
            print(('[npc_loot] Player %s [%d] attempted rapid searching'):format(GetPlayerName(src), src))
        end
        TriggerClientEvent('qbx_core:Notify', src, 'You are searching too quickly', 'error')
        return
    end
    
    -- Mark body as searched immediately to prevent race conditions
    searchedBodies[uniqueId] = true
    
    -- Update rate limiting timestamp
    lastSearchTime[src] = currentTime
    
    local reward = getRandomSearchReward()
    
    if reward.item == nil then
        -- Nothing found
        TriggerClientEvent('qbx_core:Notify', src, 'You found nothing of value', 'error')
    elseif reward.item == 'money' then
        if exports.ox_inventory:CanCarryItem(src, 'money', reward.amount) then
            exports.ox_inventory:AddItem(src, 'money', reward.amount)
            TriggerClientEvent('qbx_core:Notify', src, ('You found $%d'):format(reward.amount), 'success')
        else
            TriggerClientEvent('qbx_core:Notify', src, 'Your pockets are too full', 'error')
        end
    else
        if exports.ox_inventory:CanCarryItem(src, reward.item, reward.amount) then
            exports.ox_inventory:AddItem(src, reward.item, reward.amount)
            TriggerClientEvent('qbx_core:Notify', src, ('You found %dx %s'):format(reward.amount, reward.item), 'success')
        else
            TriggerClientEvent('qbx_core:Notify', src, 'Your pockets are too full', 'error')
        end
    end
end)

-- Clean up rate limiting data on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    if lastSearchTime[src] then
        lastSearchTime[src] = nil
    end
end)

-- Periodic cleanup of rate limiting data (every 10 minutes)
CreateThread(function()
    while true do
        Wait(600000) -- 10 minutes
        local currentTime = GetGameTimer()
        
        for playerId, lastTime in pairs(lastSearchTime) do
            -- Remove old entries (older than 1 hour)
            if (currentTime - lastTime) > 3600000 then
                lastSearchTime[playerId] = nil
            end
        end
    end
end)

-- Periodic cleanup of searched bodies (every 30 minutes to prevent memory buildup)
CreateThread(function()
    while true do
        Wait(1800000) -- 30 minutes
        
        -- Clear old searched bodies to prevent infinite growth
        -- Bodies "decay" after 30 minutes and can theoretically be searched again
        -- This is reasonable as NPCs despawn and respawn naturally
        local count = 0
        for _ in pairs(searchedBodies) do count = count + 1 end
        
        if count > 1000 then -- If we have more than 1000 tracked bodies, clear them
            searchedBodies = {}
            if config.debugMode then
                print('[npc_loot] Cleaned up searched bodies tracker')
            end
        end
    end
end)