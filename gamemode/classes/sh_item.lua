--[[
File:    classes/sh_item.lua
Purpose: Creates the item class which is a usable object for a character.
--]]

local ITEM = nut.meta.item or {}
ITEM.__index = ITEM
ITEM.id = "unknown"
ITEM.name = "Unknown"
ITEM.model = "models/error.mdl"

-- Returns the string representation of the item.
function ITEM:__tostring()
    return "item["..self.id.."]"
end

-- Deletes an item from existence.
function ITEM:delete()
    error("ITEM:delete() has not been overwritten!")
end

nut.meta.item = ITEM
