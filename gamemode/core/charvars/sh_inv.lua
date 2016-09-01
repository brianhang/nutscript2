--[[
File:    core/charvars/sh_inv.lua
Purpose: Adds the ability to store inventories for characters.
--]]

-- The number of bits in a long.
local LONG = 32

nut.char.registerVar("inv", {
    default = {},
    isConstant = true,
    onLoad = function(character)
        -- Network and store the restored inventory.
        local function setupInventory(inventory, index)
            if (not character) then
                return
            end

            -- Get who to send the inventory information to.
            local client = character:getPlayer()

            if (not IsValid(client)) then
                return
            end

            -- Store the inventory in the character.
            character.vars.inv[index] = inventory

            -- Send the inventory information to the player.
            net.Start("nutInventoryInstance")
                net.WriteInt(inventory:getID(), LONG)
                net.WriteInt(inventory:getOwner(), LONG)
                net.WriteInt(index, LONG)
            net.Send(client)

            -- After, send all the items to the player.
            inventory:sync(client)
        end

        -- Load all the inventories that belongs to the character.
        nut.item.restoreInvFromOwner(character:getID(),
        function(inventory, index)
            -- Setup the inventory for use when loaded. If the character does
            -- not have a inventory, create one.
            if (inventory) then
                setupInventory(inventory, index)
            else
                local owner = character:getID()

                if (hook.Run("InventoryInitialCreation", owner) ~= false) then
                    nut.item.createInv(owner, function(inventory)
                        setupInventory(inventory, 1)
                    end)
                end
            end
        end)
    end,
    onSave = function(character)
        -- Save all the character's inventories.
        for _, inventory in ipairs(character.vars.inv) do
            if (type(inventory.save) == "function") then
                inventory:save()
            end
        end

        return false
    end,
    onGet = function(character, index)
        if (type(index) ~= "number") then
            index = 1
        end

        return character.vars.inv[index]
    end,
    onDestroy = function(id)
        -- Remove the inventory instance.
        nut.item.inventories[id] = nil

        -- Remove replications of the inventory on clients.
        net.Start("nutInventoryDestroy")
            net.WriteInt(id, LONG)
        net.Broadcast()
    end,
    replication = CHARVAR_NONE
})

-- Handling networking for inventories.
if (SERVER) then
    util.AddNetworkString("nutInventoryInstance")
    util.AddNetworkString("nutInventoryDestroy")
else
    -- Replicate an inventory instance from the server.
    net.Receive("nutInventoryInstance", function()
        local id = net.ReadInt(LONG)
        local owner = net.ReadInt(LONG)
        local index = net.ReadInt(LONG)

        -- Replicate the inventory object on the client.
        local inventory = nut.item.newInv(id, owner)

        -- Store it in the given owner.
        local character = nut.char.list[owner]

        if (character) then
            character.vars.inv[index] = inventory
        end
    end)

    -- Destroy an inventory instance.
    net.Receive("nutInventoryDestroy", function()
        local id = net.ReadInt(LONG)

        nut.item.inventories[id] = nil
    end)
end