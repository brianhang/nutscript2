--[[
File:    classes/sh_character.lua
Purpose: Defines the character class here which is used to store data
         related to a character.
--]]

-- The DT variable for character ID.
CHAR_ID = 31

-- The number of bits in a longer number.
local LONG = 32

local CHARACTER = nut.meta.character or {}
CHARACTER.__index = CHARACTER
CHARACTER.id = 0
CHARACTER.vars = {}

-- Finds a player whose active character matches a given ID.
local function findPlayerByCharID(id)
    for _, client in ipairs(player.GetAll()) do
        if (client:GetDTInt(CHAR_ID) == id) then
            return client
        end
    end
end

-- Returns a string representation of the character.
function CHARACTER:__tostring()
    return "character["..self.id.."]"
end

-- Returns whether or not two characters are equal by checking for ID.
function CHARACTER:__eq(other)
    return self.id == other.id
end

-- Deallocates a character.
function CHARACTER:destroy()
    nut.char.delete(self:getID(), nil, true)
end

-- Gets the numeric ID for the character.
function CHARACTER:getID()
    return self.id
end

-- Micro-optimizations for getPlayer.
local isValid = IsValid

-- Gets the player that is the owner of the character.
function CHARACTER:getPlayer()
    self.player = isValid(self.player) and
                  self.player.getChar(self.player) == self and
                  self.player or findPlayerByCharID(self.id)

    return self.player
end

if (SERVER) then
    -- Number of seconds in a minute.
    local MINUTE = 60

    -- Prevents this character from being used.
    function CHARACTER:ban(time, reason)
        -- Get when the ban will expire.
        local expiration = 0

        if (time) then
            time = tonumber(time) or MINUTE
            expiration = os.time() + time
        else
            time = 0
        end

        -- Store the expiration time.
        self:setData("ban", expiration)

        -- Store the reason as well.
        if (reason) then
            self:setData("banReason", tostring(reason))
        end

        hook.Run("CharacterBanned", self, time,
                 reason and tostring(reason) or "")
    end
    
    -- Deletes this character permanently.
    function CHARACTER:delete()
        nut.char.delete(self:getID())
    end

    -- Ejects the owner of this character.
    function CHARACTER:kick(reason)
        -- Stop this character from being an active character for a player.
        local client = self:getPlayer()
        
        if (IsValid(client) and client:getChar() == self) then
            client:SetDTInt(CHAR_ID, 0)
        end

        hook.Run("CharacterKicked", self, client, reason)
    end

    -- Saves the character to the database.
    function CHARACTER:save(callback)
        -- The data for the update query.
        local data = {}

        -- Save each applicable variable.
        for name, variable in pairs(nut.char.vars) do
            -- If onSave is given, overwrite the normal saving.
            if (type(variable.onSave) == "function") then
                variable.onSave(self)

                continue
            end

            -- Ignore constant variables and variables without SQL fields.
            if (not variable.field or variable.isConstant) then
                continue
            end

            -- Get the character's value for this variable.
            local value = self.vars[name]

            -- Make sure not null variables are not updated to null.
            if (variable.notNull and value == nil) then
                ErrorNoHalt("Tried to set not null '"..name.."' to null"..
                            " for character #"..self.id.."!\n")

                continue
            end

            data[variable.field] = value
        end

        -- Run the update query.
        nut.db.update(CHARACTERS, data, "id = "..self.id, callback)

        hook.Run("CharacterSave", self)
    end

    -- Sets up a player to reflect this character.
    function CHARACTER:setup(client)
        assert(type(client) == "Player", "client is not a player")
        assert(IsValid(client), "client is not a valid player")

        -- Set the player's active character to be this character.
        client:SetDTInt(CHAR_ID, self:getID())

        -- Set up all the character variables.
        for _, variable in pairs(nut.char.vars) do
            if (type(variable.onSetup) == "function") then
                variable.onSetup(self, client)
            end
        end

        hook.Run("CharacterSetup", self, client)
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
                variable.onSync(self, recipient) == false) then
                continue
            end
            
            -- Network this variable.
            net.Start("nutCharVar")
                net.WriteInt(self:getID(), LONG)
                net.WriteString(name)
                net.WriteType(self.vars[name])
            net.Send(recipient)
        end

        hook.Run("CharacterSync", self, recipient)
    end

    -- Allows the character to be used again.
    function CHARACTER:unban()
        -- Clear the ban status.
        if (self:getData("ban")) then
            self:setData("ban", nil)
        end

        -- Clear the ban reason.
        if (self:getData("banReason")) then
            self:setData("banReason", nil)
        end

        hook.Run("CharacterUnbanned", self)
    end
end

nut.meta.character = CHARACTER
