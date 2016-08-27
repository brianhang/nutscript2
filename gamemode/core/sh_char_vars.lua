--[[
File:    core/sh_char_vars.lua
Purpose: Sets up default character variables.
--]]

-- The number of bits in a long number.
local LONG = 32

-- The open curly brace position.
local TABLE_START = 2

-- The close curly brace position.
local TABLE_END = -2

nut.char.registerVar("id", {
    default = -1,
    field = "id",
    isConstant = true,
    onSave = CHARVAR_NOSAVE,
    replication = CHARVAR_PUBLIC,
})

nut.char.registerVar("name", {
    default = "",
    field = "name",
    replication = CHARVAR_PUBLIC,
    notNull = true
})

nut.char.registerVar("desc", {
    default = "",
    field = "desc",
    replication = CHARVAR_PUBLIC
})

nut.char.registerVar("model", {
    default = "models/error.mdl",
    field = "model",
    onSet = function(character, value)
        local client = character:getPlayer()

        if (IsValid(client)) then
            client:SetModel(value)
            client:SetupHands()
        end
    end,
    onSetup = function(character, client)
        client:SetModel(character:getModel())
        client:SetupHands()
    end,
    replication = CHARVAR_PUBLIC
})

nut.char.registerVar("money", {
    default = 0,
    field = "money" 
})

nut.char.registerVar("team", {
    default = 0,
    field = "team",
    onSet = function(character, value)
        local client = character:getPlayer()

        if (IsValid(client)) then
            client:SetTeam(value)
        end
    end,
    onSetup = function(character, client)
        client:SetModel(character:getModel())
    end,
    replication = CHARVAR_PUBLIC
})

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

nut.char.registerVar("data", {
    default = {},
    onDelete = function(id)
        assert(type(id) == "number", "ID must be a number")

        nut.db.delete(CHAR_DATA, "id = "..id)
    end,
    onLoad = function(character)
        local id = character:getID()

        -- Load all the previous set data values.
        nut.db.select(CHAR_DATA, {"key", "value"}, "id = "..id, function(data)
            if (not data) then
                return
            end

            -- Store all the data into the character's data.
            for i = 1, #data do
                local key = data[i].key
                local value = data[i].value
                local status, result = pcall(pon.decode, "{"..value.."}")

                if (status) then
                    character.vars.data[key] = result[1]
                end
            end
        end)
    end,
    onSet = function(character, key, value, recipient)
        -- Store the old value for the hook.
        local oldValue = character.vars.data[key]

        -- Set the data value.
        character.vars.data[key] = value

        -- Update the character data in the database.
        local query

        if (value ~= nil) then
            -- Get the encoded data.
            local status, result = pcall(pon.encode, {value})

            if (not status) then
                ErrorNoHalt("Failed to set data '"..key.."' to '"..
                            tostring(value).."' due to encoding error!\n")

                return false
            end

            local encoded = result:sub(TABLE_START, TABLE_END)
            
            -- Create a query to update the data.
            query = "REPLACE INTO "..CHAR_DATA.." (`id`, `key`, `value`) "..
                    "VALUES (%s, '%s', '%s')"
            query = query:format(character:getID(),
                                 nut.db.escape(tostring(key)),
                                 nut.db.escape(encoded))
        else
            -- Delete if nil since storing it is not needed.
            query = "DELETE FROM "..CHAR_DATA.." WHERE `id`=%s AND `key`='%s'"
            query = query:format(character:getID(),
                                 nut.db.escape(tostring(key)))
        end

        nut.db.query(query)

        -- Don't do any networking if it is not wanted.
        if (recipient == false) then
            return false
        end

        net.Start("nutCharData")
        net.WriteInt(character:getID(), 32)
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

        hook.Run("CharacterDataChanged", character, key, oldValue, value)

        -- Don't do anything else after.
        return false
    end,
    onGet = function(character, key, default)
        return character.vars.data[key] or default
    end
})

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
        net.WriteInt(character:getID(), 32)
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

nut.char.registerVar("owner", {
    default = "",
    field = "steamID",
    onSet = function(character, steamID)
        -- Convert players to a 64-bit SteamID.
        if (type(steamID) == "Player") then
            if (not IsValid(steamID)) then
                error("The new owner is not a valid player")
            end

            steamID = steamID:SteamID64() or 0
        elseif (type(steamID) ~= "string") then
            error("The new owner must be a player or a string")
        end

        -- Remove the old owner.
        local oldOwner = character:getPlayer()

        if (IsValid(oldOwner) and oldOwner:getChar() == character) then
            character:kick()
        end

        hook.Run("CharacterTransferred", character, oldOwner, steamID)

        -- Update the database immediately.
        steamID = nut.db.escape(steamID)
        nut.db.query("UPDATE "..CHARACTERS.." SET steamID = "..steamID..
                     " WHERE id = "..character:getID())

        -- Override owner to be the SteamID if it was a player.
        return true, steamID
    end,
    onSave = CHARVAR_NOSAVE,
    replication = CHARVAR_PUBLIC
})
