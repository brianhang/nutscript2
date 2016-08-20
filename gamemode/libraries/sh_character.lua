--[[
File:    libraries/sh_character.lua
Purpose: Creates functions to create and manage characters. 
--]]

-- How many bits are in a long integer.
local LONG = 32

-- Get the second character within a string.
local SECOND = 2

-- Global enums for types of character variable networking.
CHARVAR_PUBLIC = 0
CHARVAR_PRIVATE = 1
CHARVAR_NONE = 2

nut.char = nut.char or {}
nut.char.list = nut.char.list or {}
nut.char.vars = {}

if (CLIENT) then
    -- Removes a character on the client.
    net.Receive("nutCharDelete", function()
        local id = net.ReadUInt(32)

        nut.char.delete(id)
    end)
end

-- Deletes a character from existence.
function nut.char.delete(id, callback)
    assert(type(id) == "number", "id is not a number")

    -- Remove the character object.
    nut.char.list[id] = nil

    if (SERVER) then
        -- Remove the character entry in the database.
        nut.db.delete("characters", "id = "..id, function()
            if (type(callback) == "function") then
                callback()
            end

            hook.Run("CharacterDeleted", id)

            -- Notify the clients to remove the character.
            net.Start("nutCharDelete")
                net.WriteUInt(id, LONG)
            net.Broadcast()
        end)
    else
        hook.Run("CharacterDeleted", id)
    end
end

-- Creates a character object.
function nut.char.new(id)
    assert(type(id) == "number", "id is not a number")

    local character = setmetatable({}, nut.meta.character)
    character.id = id

    nut.char.list[id] = character

    return character
end

-- Sets up a character variable for use.
function nut.char.registerVar(name, info)
    assert(type(info) == "table", "info is not a table")

    -- Set some default values for the parameters.
    name = tostring(name)
    info.replication = info.replication or CHARVAR_PRIVATE

    -- Get the character metatable so we can add setters/getters.
    local character = nut.meta.character

    -- Get a CamelCase version of name.
    local upperName = name:sub(1, 1):upper()..name:sub(SECOND)

    -- Store the default in the metatable.
    character.vars[name] = info.default

    -- Create a getter function.
    if (type(info.onGet) == "function") then
        character["get"..upperName] = info.onGet
    else
        character["get"..upperName] = function(self)
            return self.vars[name]
        end
    end

    -- Create the setter function.
    if (not info.isConstant) then
        -- Whether or not info.set is a function.
        local customSet = type(info.set) == "function"

        -- Determine how the variable will be networked.
        local send

        if (info.replication == CHARVAR_PUBLIC) then
            send = net.Broadcast
        elseif (info.replication == CHARVAR_PRIVATE) then
            send = function(self)
                local client = self:getPlayer()

                if (IsValid(client)) then
                    net.Send(client)
                end
            end
        elseif (type(info.replication) == "function") then
            send = info.replication
        end

        character["set"..upperName] = function(self, value, ...)
            -- Run the custom setter if given.
            if (customSet and info.onSet(self, value, ...)) then
                return
            end

            -- Store the given value.
            self.vars[name] = value

            -- Network the variable.
            if (send) then
                net.Start("nutCharVar")
                    net.WriteUInt(self:getID(), LONG)
                    net.WriteString(name)
                    net.WriteType(value)
                send()
            end
        end
    end

    nut.char.vars[name] = info
end

-- Validates information for character creation.
function nut.char.validateInfo(info, context)
    -- Default the context to an empty table.
    context = context or {}

    -- Check with the character variables.
    for key, value in pairs(info) do
        -- Get the variable that the key corresponds to.
        local variable = nut.char.vars[key]

        -- Make sure there are no invalid variables.
        if (not variable) then
            return false, "invalid variable ("..key..")"
        end

        -- Custom check with onValidate.
        if (type(variable.onValidate) == "function") then
            local valid, reason = variable.onValidate(info[key], context)

            if (valid == false) then
                return false, reason or "invalid value for "..key
            end
        end
    end

    -- Null check for variables.
    for name, variable in pairs(nut.char.vars) do
        if (variable.notNull and not info[name]) then
            return false, name.." was not provided"
        end
    end

    -- Use the CharacterValidateInfo hook to check.
    local valid, fault = hook.Run("CharacterValidateInfo", info, context)

    if (valid == false) then
        return false, fault
    end
    
    return true
end

nut.util.include("nutscript2/gamemode/core/sh_char_vars.lua")
