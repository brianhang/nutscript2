--[[
Name:    sh_entity.lua
Purpose: Provides some utility functions that deal with entities.
--]]

local ENTITY = FindMetaTable("Entity")

-- A list of chair entities.
local CHAIR_CACHE = {}

-- Add chair models that were defined as chairs.
for _, vehicle in pairs(list.Get("Vehicles")) do
    if (vehicle.Category == "Chairs") then
        CHAIR_CACHE[vehicle.Model:lower()] = true
    end
end

-- Returns whether or not a vehicle is a chair.
function ENTITY:isChair()
    return CHAIR_CACHE[string.lower(self.GetModel(self))]
end

-- Returns whether or not an entity is locked.
function ENTITY:isLocked()
    if (self:IsVehicle()) then
        local data = self:GetSaveTable()

        if (data) then
            return data.VehicleLocked
        end
    else
        local data = self:GetSaveTable()

        if (data) then
            return data.m_bLocked
        end
    end

    return false
end

-- Returns the entity that is blocking this entity.
function ENTITY:getBlocker()
    local data = self:GetSaveTable()

    return data.pBlocker
end

-- Adds support for muting entities with entity.nutMuted.
hook.Add("EntityEmitSound", "nutEntityMute", function(data)
    if (data.Entity.nutMuted) then
        return false
    end
end)

-- Adds support for preventing entity use with entity.nutIgnoreUse.
hook.Add("PlayerUse", "nutEntityIgnoreUse", function(client, entity)
    if (entity.nutIgnoreUse) then
        return false
    end
end)
