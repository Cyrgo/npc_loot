local config = require 'config'
local QBX = exports.qbx_core

-- Local variables
local phoneBuyerNPC = nil
local phoneBuyerBlip = nil

-- Create phone buyer NPC
local function spawnPhoneBuyerNPC()
    if not config.phoneBuyer.enabled then return end
    
    local npcConfig = config.phoneBuyer.npc
    
    -- Request model
    lib.requestModel(npcConfig.model, 5000)
    
    -- Create NPC
    phoneBuyerNPC = CreatePed(0, npcConfig.model, npcConfig.coords.x, npcConfig.coords.y, npcConfig.coords.z, npcConfig.coords.w, false, false)
    
    -- Configure NPC
    SetModelAsNoLongerNeeded(npcConfig.model)
    FreezeEntityPosition(phoneBuyerNPC, true)
    SetEntityInvincible(phoneBuyerNPC, true)
    SetBlockingOfNonTemporaryEvents(phoneBuyerNPC, true)
    
    -- Set scenario
    TaskStartScenarioInPlace(phoneBuyerNPC, npcConfig.scenario, 0, true)
    
    -- Add target interaction
    exports.ox_target:addLocalEntity(phoneBuyerNPC, {
        {
            name = 'phone_buyer',
            icon = 'fas fa-mobile-alt',
            label = 'Sell Phone',
            distance = 2.0,
            onSelect = function()
                openPhoneSellMenu()
            end,
            canInteract = function()
                return exports.ox_inventory:Search('count', 'phone') > 1
            end
        }
    })
end

-- Create blip for phone buyer
local function createPhoneBuyerBlip()
    if not config.phoneBuyer.enabled then return end
    
    local blipConfig = config.phoneBuyer.blip
    local coords = config.phoneBuyer.npc.coords
    
    phoneBuyerBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(phoneBuyerBlip, blipConfig.sprite)
    SetBlipDisplay(phoneBuyerBlip, blipConfig.display)
    SetBlipScale(phoneBuyerBlip, blipConfig.scale)
    SetBlipAsShortRange(phoneBuyerBlip, true)
    SetBlipColour(phoneBuyerBlip, blipConfig.colour)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blipConfig.label)
    EndTextCommandSetBlipName(phoneBuyerBlip)
end

-- Open phone selling menu
function openPhoneSellMenu()
    local phoneCount = exports.ox_inventory:Search('count', 'phone')
    
    if phoneCount <= 1 then
        QBX:Notify('You need to keep at least one phone for personal use', 'error')
        return
    end
    
    local input = lib.inputDialog('Sell Phones', {
        {
            type = 'number',
            label = 'Amount',
            description = 'How many phones do you want to sell?',
            icon = 'mobile-alt',
            required = true,
            min = 1,
            max = phoneCount - 1
        }
    })
    
    if input and input[1] then
        local amount = tonumber(input[1])
        if amount and amount > 0 and amount <= phoneCount then
            TriggerServerEvent('npc_loot:server:sellPhone', amount)
        else
            QBX:Notify('Invalid amount', 'error')
        end
    end
end

-- Clean up function
local function deletePhoneBuyerNPC()
    if phoneBuyerNPC then
        DeletePed(phoneBuyerNPC)
        phoneBuyerNPC = nil
    end
end

local function deletePhoneBuyerBlip()
    if phoneBuyerBlip then
        RemoveBlip(phoneBuyerBlip)
        phoneBuyerBlip = nil
    end
end

-- Event handlers
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createPhoneBuyerBlip()
    spawnPhoneBuyerNPC()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end
    createPhoneBuyerBlip()
    spawnPhoneBuyerNPC()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    deletePhoneBuyerBlip()
    deletePhoneBuyerNPC()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    deletePhoneBuyerBlip()
    deletePhoneBuyerNPC()
end)