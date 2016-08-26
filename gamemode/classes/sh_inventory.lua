--[[
File:    classes/sh_inventory.lua
Purpose: Defines the inventory class which is a container for items.
--]]

local INVENTORY = nut.meta.inventory or {}
INVENTORY.__index = INVENTORY
INVENTORY.id = 0

-- Returns the string representation of the inventory.
function INVENTORY:__tostring()
    return "inventory["..self.id.."]"
end

-- Returns whether or not two inventories are the same.
function INVENTORY:__eq(other)
    return self.id == other.id
end

-- Gets the numeric ID for the inventory.
function INVENTORY:getID()
    return self.id
end

-- Adds an item to the inventory.
function INVENTORY:add()
    error("INVENTORY:add() has not been overwritten!")
end

-- Deletes the inventory from existence along with its items.
function INVENTORY:delete()
    error("INVENTORY:delete() has not been overwritten!")
end

-- Removes an item to the inventory.
function INVENTORY:remove()
    error("INVENTORY:remove() has not been overwritten!")
end

-- Returns the owning character's ID.
function INVENTORY:getOwner()
    error("INVENTORY:getOwner() has not been overwritten!")
end

-- Removes an item from the inventory.
function INVENTORY:remove()
    error("INVENTORY:remove() has not been overwritten!")
end

-- Sets the owner of the inventory.
function INVENTORY:setOwner()
    error("INVENTORY:setOwner() has not been overwritten!")
end

-- Synchronizes the items within the inventory.
function INVENTORY:sync()
    error("INVENTORY:sync() has not been overwritten!")
end

nut.meta.inventory = INVENTORY
