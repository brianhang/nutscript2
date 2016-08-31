--[[
File:    core/charvars/sh_data.lua
Purpose: Allows for arbitrary data to be stored for characters.
--]]

-- The open curly brace position.
local TABLE_START = 2

-- The close curly brace position.
local TABLE_END = -2

-- The number of bits in a long.
local LONG = 32

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

        hook.Run("CharacterDataChanged", character, key, oldValue, value)

        -- Don't do anything else after.
        return false
    end,
    onGet = function(character, key, default)
        return character.vars.data[key] or default
    end
})

-- Handle networking of character data.
if (SERVER) then
    util.AddNetworkString("nutCharData")
else
    -- Sets a character data value.
    net.Receive("nutCharData", function()
        -- Read the information.
        local id = net.ReadInt(LONG)
        local key = net.ReadString()
        local value = net.ReadType()

        -- Get the character from the ID.
        local character = nut.char.list[id] or nut.char.new(id)
        local oldValue = character.vars.data[key]

        -- Update the data value.
        character.vars.data[key] = value
        hook.Run("CharacterDataChanged", character, key, oldValue, value)
    end)
end
