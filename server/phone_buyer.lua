local config = require 'config'
local QBX = exports.qbx_core

-- Rate limiting for phone sales (prevent spam)
local lastPhoneSaleTime = {}

-- Handle phone selling
RegisterNetEvent('npc_loot:server:sellPhone', function(amount)
    local src = source
    local player = QBX:GetPlayer(src)
    
    if not player then return end
    
    -- Validate input
    if not amount or type(amount) ~= 'number' or amount <= 0 then
        TriggerClientEvent('qbx_core:Notify', src, 'Invalid amount', 'error')
        return
    end
    
    -- Rate limiting (max 1 sale every 2 seconds)
    local currentTime = GetGameTimer()
    if lastPhoneSaleTime[src] and (currentTime - lastPhoneSaleTime[src]) < 2000 then
        if config.antiExploitLogging then
            print(('[npc_loot] Player %s [%d] attempted rapid phone selling'):format(GetPlayerName(src), src))
        end
        TriggerClientEvent('qbx_core:Notify', src, 'You are selling too quickly', 'error')
        return
    end
    
    -- Check if player has enough phones
    local phoneCount = exports.ox_inventory:Search(src, 'count', 'phone')
    if phoneCount < amount then
        TriggerClientEvent('qbx_core:Notify', src, 'You don\'t have enough phones', 'error')
        return
    end
    
    -- Prevent selling player's personal phone (check if they have exactly the amount they're trying to sell)
    -- This assumes players should keep at least 1 phone for personal use
    if phoneCount == amount then
        TriggerClientEvent('qbx_core:Notify', src, 'You need to keep at least one phone for personal use', 'error')
        return
    end
    
    -- Calculate payment
    local pricePerPhone = math.random(config.phoneBuyer.phonePrice.min, config.phoneBuyer.phonePrice.max)
    local totalPayment = pricePerPhone * amount
    
    -- Remove phones from inventory
    local success = exports.ox_inventory:RemoveItem(src, 'phone', amount)
    if not success then
        TriggerClientEvent('qbx_core:Notify', src, 'Failed to sell phones', 'error')
        return
    end
    
    -- Add money to player
    if not exports.ox_inventory:CanCarryItem(src, 'money', totalPayment) then
        -- Return phones if can't carry money
        exports.ox_inventory:AddItem(src, 'phone', amount)
        TriggerClientEvent('qbx_core:Notify', src, 'Your pockets are too full for the payment', 'error')
        return
    end
    
    exports.ox_inventory:AddItem(src, 'money', totalPayment)
    
    -- Update rate limiting
    lastPhoneSaleTime[src] = currentTime
    
    -- Success notification
    TriggerClientEvent('qbx_core:Notify', src, 
        ('Sold %dx phone(s) for $%d ($%d each)'):format(amount, totalPayment, pricePerPhone), 
        'success'
    )
    
    -- Debug logging
    if config.debugMode then
        print(('[npc_loot] Player %s sold %d phones for $%d'):format(GetPlayerName(src), amount, totalPayment))
    end
end)

-- Clean up rate limiting data on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    if lastPhoneSaleTime[src] then
        lastPhoneSaleTime[src] = nil
    end
end)

-- Periodic cleanup of rate limiting data (every 10 minutes)
CreateThread(function()
    while true do
        Wait(600000) -- 10 minutes
        local currentTime = GetGameTimer()
        
        for playerId, lastTime in pairs(lastPhoneSaleTime) do
            -- Remove old entries (older than 1 hour)
            if (currentTime - lastTime) > 3600000 then
                lastPhoneSaleTime[playerId] = nil
            end
        end
    end
end)