--[[
File:    utilities/sh_player.lua
Purpose: Creates utility functions relating to players on the server.
--]]

-- How often to check if a player is staring at an entity for stared actions.
local STARE_INTERVAL = 0.1

-- The maximum distance between a stared entity and player.
local STARE_DISTANCE = 96

-- How far back to check for a drop position.
local DROP_POS_BACK = 64

-- How far front to check for a drop position.
local DROP_POS_FRONT = 86

-- How much to pad the drop position.
local DROP_POS_PAD = 36

-- A barrier between walking speed and running speed.
local SPEED_BARRIER = 10

-- Create an table of female model paths.
-- Each entry should be FEMALE_MODELS[model] = true
FEMALE_MODELS = {}

-- Player metatable for extending.
local PLAYER = FindMetaTable("Player")

-- Finds a player whose name matches a string.
function nut.util.findPlayer(name, allowPatterns)
    assert(type(name) == "string", "name is not a string")

    -- Try finding direct matches first.
    for _, client in ipairs(player.GetAll()) do
        if (client:Name() == name) then
            return client
        end
    end

    -- Then try a looser search.
    if (not allowPatterns) then
        name = string.PatternSafe(name)
    end

    for _, client in ipairs(player.GetAll()) do
        if (nut.util.stringMatches(client:Name(), name)) then
            return client
        end
    end
end

-- Returns a table of admin players.
function nut.util.getAdmins(superOnly)
    local found = {}

    for _, client in ipairs(player.GetAll()) do
        if (superOnly and client:IsSuperAdmin()) then
            found[#found + 1] = client
        elseif (not superOnly and v:IsAdmin()) then
            found[#found + 1] = client
        end
    end

    return found
end

-- Check if a player is using a female player model.
function PLAYER:isFemale()
    local model = self:GetModel():lower()

    return FEMALE_MODELS[model]
           or model:find("female")
           or model:find("alyx")
           or model:find("mossman")
end

-- Perform an action after a player has stared at an entity for a while.
function PLAYER:doStaredAction(entity, time, callback, onCancel, distance)
    assert(type(callback) == "function", "callback is not a function")
    assert(type(time) == "number", "time is not a number")

    local timerID = "nutStare"..self:UniqueID()
    local trace = {filter = self}

    -- A function to cancel the stared action.
    local function cancelFunc()
        timer.Remove(timerID)

        if (onCancel) then
            onCancel()
        end
    end

    -- Make sure the player is staring at the entity. Once the time is up,
    -- run the callback.
    timer.Create(timerID, STARE_INTERVAL, time / STARE_INTERVAL, function()
        if (IsValid(self) and IsValid(entity)) then
            trace.start = self:GetShootPos()
            trace.endpos = trace.start
                           + self:GetAimVector()*(distance or STARE_DISTANCE)

            if (util.TraceLine(trace).Entity ~= entity) then
                cancelFunc()
            elseif (callback and timer.RepsLeft(timerID) == 0) then
                callback()
            end
        else
            cancelFunc()
        end
    end)

    -- Return the cancel function so the user can cancel the action themselves.
    return cancelFunc
end

-- Find a player to drop an entity in front of a player.
function PLAYER:getItemDropPos()
    local trace = util.TraceLine({
        start = self:GetShootPos() - self:GetAimVector()*DROP_POS_BACK,
        endpos = self:GetShootPos() + self:GetAimVector()*DROP_POS_FRONT,
        filter = self
    })

    return trace.HitPos + trace.HitNormal*DROP_POS_PAD
end

-- Check whether or not the player is stuck in something.
function PLAYER:isStuck()
    return util.TraceEntity({
               start = self:GetPos(),
               endpos = self:GetPos(),
               filter = self
           }, self).StartSolid
end

local length2D = FindMetaTable("Vector").Length2D

-- Check whether or not a player is running.
function PLAYER:isRunning()
    return length2D(self.GetVelocity(self)) >
           length2D(self.GetWalkSpeed(self) + SPEED_BARRIER)
end
