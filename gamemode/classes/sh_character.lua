--[[
File:    classes/sh_character.lua
Purpose: Defines the character class here which is used to store data
         related to a character.
--]]

local CHARACTER = nut.meta.character or {}
CHARACTER.__index = CHARACTER
CHARACTER.id = 0
CHARACTER.owner = ""
CHARACTER.vars = {}

function CHARACTER:getID()
    return self.id
end

if (SERVER) then
    -- Prevents this character from being used.
    function CHARACTER:ban(time, reason)
    end
    
    -- Deletes this character permanently.
    function CHARACTER:delete()
    end

    -- Ejects the owner of this character.
    function CHARACTER:kick(reason)
    end

    -- Saves the character to the database.
    function CHARACTER:save()
    end

    -- Sets up a player to reflect this character.
    function CHARACTER:setup(client)
    end

    -- Networks the character data to the given recipient(s).
    function CHARACTER:sync(recipient)
    end

    -- Allows the character to be used again.
    function CHARACTER:unban()
    end
end

nut.meta.character = CHARACTER
