local config = require 'config'
local QBX = exports.qbx_core

-- Local variables
local isSearchingNPC = false

-- Search dead NPC system
local function searchDeadNPC(ped)
    -- Validate entity exists
    if not DoesEntityExist(ped) then
        QBX:Notify('Invalid target', 'error')
        return
    end
    
    -- Double-check the NPC is actually dead (prevent exploit)
    if not IsEntityDead(ped) then
        QBX:Notify('You can only search dead bodies', 'error')
        return
    end
    
    -- Check if already searching
    if isSearchingNPC then
        QBX:Notify('Already searching', 'error')
        return
    end
    
    -- Get persistent identifier using coordinates + model (like vehicle license plates)
    local coords, model
    local success = pcall(function()
        coords = GetEntityCoords(ped)
        model = GetEntityModel(ped)
    end)
    
    -- Validate coords and model or if natives failed
    if not success or not coords or not model or model == 0 then
        QBX:Notify('Unable to search this body', 'error')
        return
    end
    
    local uniqueId = ('%d_%.2f_%.2f_%.2f'):format(model, coords.x, coords.y, coords.z)
    
    isSearchingNPC = true
    
    -- Play search animation
    lib.requestAnimDict(config.animations.search.dict)
    TaskPlayAnim(cache.ped, config.animations.search.dict, config.animations.search.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    if lib.progressBar({
        duration = 5000,
        label = 'Searching body...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        }
    }) then
        -- Progress bar completed successfully
        TriggerServerEvent('npc_loot:server:searchNPC', uniqueId, coords, model)
        ClearPedTasks(cache.ped)
    else
        -- Progress bar was cancelled
        QBX:Notify('Search interrupted', 'error')
        ClearPedTasks(cache.ped)
    end
    
    isSearchingNPC = false
end

-- Target system integration
if config.useTarget then
    -- Search dead NPCs
    exports.ox_target:addGlobalPed({
        {
            name = 'search_dead_npc',
            icon = 'fas fa-search',
            label = 'Search Body',
            onSelect = function(data)
                searchDeadNPC(data.entity)
            end,
            canInteract = function(entity)
                -- Simple validation for performance
                if not DoesEntityExist(entity) then return false end
                if not IsEntityDead(entity) or IsPedAPlayer(entity) then return false end
                
                return true -- Server-side handles duplicate checking and shows appropriate message
            end
        }
    })
else
    -- Manual key press system with optimized server calls
    local lastCheckedBody = nil
    local lastSearchStatus = false
    local lastCheckTime = 0
    
    CreateThread(function()
        while true do
            local sleep = 100
            
            local playerCoords = GetEntityCoords(cache.ped)
            local closestPed = lib.getClosestPed(playerCoords, 2.0)
            
            if closestPed and DoesEntityExist(closestPed) and IsEntityDead(closestPed) and not IsPedAPlayer(closestPed) then
                sleep = 0
                
                -- Only check server if we have a different body or haven't checked recently
                local currentTime = GetGameTimer()
                if lastCheckedBody ~= closestPed or (currentTime - lastCheckTime) > 2000 then
                    local coords = GetEntityCoords(closestPed)
                    local model = GetEntityModel(closestPed)
                    lastSearchStatus = lib.callback.await('npc_loot:server:isBodySearched', false, coords, model)
                    lastCheckedBody = closestPed
                    lastCheckTime = currentTime
                end
                
                if lastSearchStatus then
                    lib.showTextUI('Body already searched')
                else
                    lib.showTextUI('[E] Search Body')
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        lib.hideTextUI()
                        searchDeadNPC(closestPed)
                        -- Update cache since we just searched it
                        lastSearchStatus = true
                    end
                end
            else
                lib.hideTextUI()
                lastCheckedBody = nil
            end
            
            Wait(sleep)
        end
    end)
end

-- Debug command (only if debug mode is enabled)
if config.debugMode then
    RegisterCommand('npc_loot_test', function()
        local ped = lib.getClosestPed(GetEntityCoords(cache.ped), 10.0)
        if ped then
            print('Closest ped found: ' .. ped)
            print('Is dead: ' .. tostring(IsEntityDead(ped)))
            print('Ped type: ' .. GetPedType(ped))
        else
            print('No nearby peds found')
        end
    end)
end