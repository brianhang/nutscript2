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

-- Empty function for doing nothing when saving.
CHARVAR_NOSAVE = function() end

nut.char = nut.char or {}
nut.char.list = nut.char.list or {}
nut.char.vars = {}

-- Deletes a character from existence.
function nut.char.delete(id, callback, temporary)
    assert(type(id) == "number", "id is not a number")

    -- Remove the character object.
    nut.char.list[id] = nil

    if (SERVER) then
        -- Called after the character has been deleted.
        function deleted(success)
            if (type(callback) == "function") then
                callback(success)
            end

            hook.Run("CharacterDeleted", id)

            -- Destroy associated data.
            for name, variable in pairs(nut.char.vars) do
                if (type(variable.onDestroy) == "function") then
                    variable.onDestroy(id)
                end
            end

            -- Notify the clients to remove the character.
            net.Start("nutCharDelete")
                net.WriteInt(id, LONG)
            net.Broadcast()
        end

        -- If temporary, skip to the deleted callback.
        if (temporary) then
            return deleted(true)
        end

        -- Remove the character entry in the database.
        nut.db.delete(CHARACTERS, "id = "..id, deleted)

        -- Delete associated character data.
        for name, variable in pairs(nut.char.vars) do
            if (type(variable.onDelete) == "function") then
                variable.onDelete(id)
            end
        end
    else
        hook.Run("CharacterDeleted", id)
    end
end

-- Creates a character object.
function nut.char.new(id)
    assert(type(id) == "number", "id is not a number")

    -- Create a character object.
    -- Note vars is deep copied so there are no side effects.
    local character = setmetatable({
        id = id,
        vars = {}
    }, nut.meta.character)

    -- Set the variables to their default values.
    for name, variable in pairs(nut.char.vars) do
        character.vars[name] = variable.onGetDefault()
    end

    -- Store the character for later use.
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

    -- Create a function to get the default value.
    if (type(info.onGetDefault) ~= "function") then
        if (type(info.default) == "table") then
            info.onGetDefault = function() return table.Copy(info.default) end
        else
            info.onGetDefault = function() return info.default end
        end
    end

    -- Store the default in the metatable.
    character.vars[name] = info.onGetDefault()

    -- Create a getter function.
    if (type(info.onGet) == "function") then
        character["get"..upperName] = info.onGet
    else
        character["get"..upperName] = function(self)
            return self.vars[name]
        end
    end

    -- Create the setter function.
    if (SERVER and not info.isConstant) then
        -- Whether or not info.set is a function.
        local customSet = type(info.onSet) == "function"

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
            if (customSet) then
                local override, newValue = info.onSet(self, value, ...)

                if (override) then
                    value = newValue
                else
                    return
                end
            end

            -- Get the current value before it is changed for the hook.
            local oldValue = self.vars[name]

            -- Store the given value.
            self.vars[name] = value

            -- Network the variable.
            if (send) then
                net.Start("nutCharVar")
                    net.WriteInt(self:getID(), LONG)
                    net.WriteString(name)
                    net.WriteType(value)
                send(self)
            end

            hook.Run("CharacterVarChanged", self, name, oldValue, value)
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

-- Set up character variables.
nut.util.includeDir("core/charvars")

-- Create a function to get characters from players.
local PLAYER = FindMetaTable("Player")

function PLAYER:getChar()
    return nut.char.list[self:GetDTInt(CHAR_ID)]
end

-- Handle networking of character variables.
if (CLIENT) then
    -- Removes a character on the client.
    net.Receive("nutCharDelete", function()
        -- Get the character that is being removed.
        local id = net.ReadInt(LONG)

        -- Remove the character.
        nut.char.delete(id)
        hook.Run("CharacterDeleted", id)
    end)

    -- Sets a character variable.
    net.Receive("nutCharVar", function()
        -- Read the information.
        local id = net.ReadInt(LONG)
        local key = net.ReadString()
        local value = net.ReadType()

        -- Get the character from the ID.
        local character = nut.char.list[id] or nut.char.new(id)
        local oldValue = character.vars[key]

        -- Update the variable.
        character.vars[key] = value
        hook.Run("CharacterVarChanged", character, key, oldValue, value)
    end)
end