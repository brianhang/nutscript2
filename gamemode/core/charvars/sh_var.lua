--[[
File:    core/charvars/sh_var.lua
Purpose: Allows for networked, temporary variables to be set for characters.
--]]

-- How many bits are in a long.
local LONG = 32

nut.char.registerVar("var", {
    default = {},
    onSet = function(character, key, value, recipient)
        -- Store the old value for the hook.
        local oldValue = character.vars.var[key]

        -- Set the temporary variable.
        character.vars.var[key] = value

        -- If no recipient is desired, don't network the variable.
        if (recipient == false) then
            return
        end

        net.Start("nutCharTempVar")
        net.WriteInt(character:getID(), LONG)
        net.WriteString(key)
        net.WriteType(value)

        -- Determine who to send the variable to.
        if (not recipient and IsValid(character:getPlayer())) then
            net.Send(character:getPlayer())
        elseif (type(recipient) == "table" or type(recipient) == "Player") then
            net.Send(recipient)
        else
            net.Broadcast()
        end

        hook.Run("CharacterTempVarChanged", character, key, oldValue, value)

        -- Don't do anything else after.
        return false
    end,
    onGet = function(character, key, default)
        return character.vars.var[key] or default
    end
})

if (SERVER) then
    util.AddNetworkString("nutCharTempVar")
else
    -- Sets a character temporary variable.
    net.Receive("nutCharTempVar", function()
        -- Read the information.
        local id = net.ReadInt(LONG)
        local key = net.ReadString()
        local value = net.ReadType()

        -- Get the character from the ID.
        local character = nut.char.list[id] or nut.char.new(id)
        local oldValue = character.vars.var[key]

        -- Update the data value.
        character.vars.var[key] = value
        hook.Run("CharacterTempVarChanged", character, key, oldValue, value)
    end)
end