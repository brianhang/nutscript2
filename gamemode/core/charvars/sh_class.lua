--[[
File:    core/charvars/sh_class.lua
Purpose: Allows characters to be divided into classes within a team.
--]]

-- Alias for class data value.
nut.char.registerVar("class", {
    default = 0,
    onGet = function(character)
        return character:getData("class", 0)
    end,
    onSet = function(character, value)
        local oldClass = character:getClass()

        character:setData("class", value)
        hook.Run("CharacterClassChanged", character, oldClass, value)

        return false
    end,
    replication = CHARVAR_NONE
})