--[[
File:    sh_character.lua
Purpose: Creates functions to create and manage characters. 
--]]

if (not nut.db) then
    nut.util.include("sv_database.lua")
end

util.AddNetworkString("nutCharDelete")

-- How many bits are in a long integer.
local LONG = 32

nut.char = nut.char or {}
nut.char.list = nut.char.list or {}
nut.char.vars = {}

if (SERVER) then
    -- Inserts and instances a character.
    function nut.char.create(info, callback, context)
        assert(type(info) == "table", "info is not a table")

        context = context or {}

        -- Check if the player can create a character.
        local fault = hook.Run("CharacterPreCreate", info, context)

        if (type(fault) == "string") then
            return false, fault
        end

        -- Allow modifications to the given info.
        hook.Run("CharacterAdjustInfo", info, context)

        -- Make sure there are no extraneous variables.
        for k, v in pairs(info) do
            if (not nut.char.vars[k]) then
                return false, "invalid variable ("..k..")"
            end
        end

        -- Insert the character into the database.
        return nut.char.insert(info, function(id)
            local character

            if (id) then
                -- If the character was made, make an object for it and
                -- copy the given info to the character object.
                character = nut.char.new(id)

                for k, v in pairs(info) do
                    character.vars[k] = v
                end

                hook.Run("CharacterCreated", character, context)
            end

            if (type(callback) == "function") then
                callback(character)
            end
        end)
    end

    -- Inserts a character into the database.
    function nut.char.insert(info, callback)
        
    end

    -- The queries needed to create tables for NutScript characters.
    local MYSQL_CHARACTER = [[
    CREATE TABLE IF NOT EXISTS `%s` (
        id INT UNSIGNED NOT NULL AUTO_INCREMENT,
        name VARCHAR NOT NULL,
        desc TEXT,
        model VARCHAR NOT NULL,
        createTime INT UNSIGNED NOT NULL,
        lastJoin INT UNSIGNED DEFAULT 0,
        money INT UNSIGNED DEFAULT 0,
        team TINYINT UNSIGNED DEFAULT NULL,
        steamID BIGINT UNSIGNED NOT NULL,
        PRIMARY KEY (id)
    );
    ]]

    local MYSQL_CHAR_DATA = [[
    CREATE TABLE IF NOT EXISTS `%s` (
        dataID INT UNSIGNED NOT NULL AUTO_INCREMENT,
        id INT UNSIGNED NOT NULL,
        key VARCHAR NOT NULL,
        value VARCHAR NOT NULL,
        PRIMARY KEY (dataID)
    );
    ]]

    local SQLITE_CHARACTER = [[
    CREATE TABLE IF NOT EXISTS `%s` (
        id UNSIGNED INTEGER PRIMARY KEY,
        name TEXT,
        desc TEXT,
        model TEXT,
        createTime UNSIGNED INTEGER,
        lastJoin UNSIGNED INTEGER,
        money UNSIGNED INTEGER,
        team UNSIGNED INTEGER,
        steamID  UNSIGNED INTEGER
    );
    ]]

    local SQLITE_CHAR_DATA = [[
    CREATE TABLE IF NOT EXISTS `%s` (
        dataID UNSIGNED INTEGER PRIMARY KEY,
        id UNSIGNED INTEGER,
        key TEXT,
        value TEXT
    );
    ]]

    -- Sets up the character table 
    hook.Add("Initialize", "nutCharTableSetup", function()
        -- Set global variables for the character tables.
        CHARACTER = engine.ActiveGamemode():lower().."_characters"
        CHAR_DATA = engine.ActiveGamemode():lower().."_chardata"
        print(engine.ActiveGamemode()) 
        -- Create the tables themselves.
        if (nut.db.sqlModule == nut.db.modules.sqlite) then
            nut.db.query(SQLITE_CHARACTER:format(CHARACTER))
            nut.db.query(SQLITE_CHAR_DATA:format(CHAR_DATA))
        else
            nut.db.query(MYSQL_CHARACTER:format(CHARACTER))
            nut.db.query(MYSQL_CHAR_DATA:format(CHAR_DATA))
        end
    end)
else
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
