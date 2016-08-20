--[[
File:    classes/sh_character.lua
Purpose: Defines the character class here which is used to store data
         related to a character.
--]]

-- The number of bits in a longer number.
local LONG = 32

local CHARACTER = nut.meta.character or {}
CHARACTER.__index = CHARACTER
CHARACTER.id = 0
CHARACTER.vars = {}

-- Gets the numeric ID for the character.
function CHARACTER:getID()
    return self.id
end

-- Gets the player that is the owner of the character.
function CHARACTER:getPlayer()
    self.player = IsValid(self.player) and self.player or
                  player.GetBySteamID64(self:getOwner())

    return self.player
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
        -- Whether or not recipient is a table.
        local isTable = type(recipient) == "table"

        -- Default synchronizing to everyone.
        if (type(recipient) ~= "Player" and not isTable) then
            recipient = player.GetAll()
            isTable = true
        end

        -- Sync a list of players by syncing them individually.
        if (isTable) then
            for k, v in ipairs(recipient) do
                if (type(v) == "Player" and IsValid(v)) then
                    self:sync(v)
                end
            end

            return
        end

        assert(IsValid(recipient), "recipient is not a valid player")

        -- Synchronize all applicable variables.
        for name, variable in pairs(nut.char.vars) do
            -- Ignore variables that do not need any networking.
            if (variable.replication == CHARVAR_NONE) then
                continue
            end

            -- Keep private variables to the owner only.
            if (variable.replication == CHARVAR_PRIVATE and
                recipient ~= self:getPlayer()) then
                continue
            end

            -- Allow for custom synchronization.
            if (type(variable.onSync) == "function" and
                variable.onSync(recipient, character) == false) then
                continue
            end
            
            -- Network this variable.
            net.Start("nutCharVar")
                net.WriteUInt(self:getID(), LONG)
                net.WriteString(name)
                net.WriteType(self.vars[name])
            net.Send(recipient)
        end

        hook.Run("CharacterSync", recipient, self)
    end

    -- Allows the character to be used again.
    function CHARACTER:unban()
    end
end

nut.meta.character = CHARACTER
