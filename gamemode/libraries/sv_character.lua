--[[
File:    libraries/sv_database.lua
Purpose: Creates the functions responsible for managing characters between
         the server and the database.
--]]

util.AddNetworkString("nutCharData")

if (not nut.char) then
    nut.util.include("sh_character.lua")
end

if (not nut.db) then
    nut.util.include("sv_database.lua")
end

util.AddNetworkString("nutCharDelete")

-- How many bits are in a long integer.
local LONG = 32

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
    nut.char.insert(info, function(id)
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

    return true
end

-- Inserts a character into the database.
function nut.char.insert(info, callback)
    assert(type(info) == "table", "info is not a table")

    -- Create a table to store what values will be inserted.
    local data = {}

    -- Get the data to insert into the database.
    for name, variable in pairs(nut.char.vars) do
        if (variable.field and not variable.isConstant) then
            local value = info[name] or variable.default

            if (variable.notNull and value == nil) then
                error(name.." can not be null")
            end

            data[variable.field] = value
        end
    end

    -- Add some creation information.
    data.steamID = info.steamID or ""
    data.createTime = os.time()
    data.lastJoin = data.createTime

    -- Insert the data into the database.
    nut.db.insert(CHARACTERS, data, function(result)
        -- Run the callback with the resulting data.
        if (result and type(callback) == "function") then
            callback(nut.db.getInsertID())
        elseif (type(callback) == "function") then
            callback()
        end
    end)
end

-- Loads a character from the database into an instance.
function nut.char.load(id, callback)
    assert(type(id) == "number", "id is not a number")
    assert(id >= 0, "id can not be negative")

    -- Get the fields that are needed to load the character.
    local fields = {}

    for name, variable in pairs(nut.char.vars) do
        if (variable.field) then
            fields[#fields + 1] = variable.field
        end
    end

    -- Load the data from the database.
    nut.db.select(CHARACTERS, fields, "id = "..id, function(result)
        PrintTable(result)
    end, 1)
end

-- The queries needed to create tables for NutScript characters.
local MYSQL_CHARACTER = [[
CREATE TABLE IF NOT EXISTS `%s` (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR NOT NULL,
    desc TEXT,
    model VARCHAR NOT NULL,
    createTime INT UNSIGNED NOT NULL,
    lastJoin INT UNSIGNED NOT NULL DEFAULT 0,
    money INT UNSIGNED NOT NULL DEFAULT 0,
    team TINYINT UNSIGNED,
    steamID BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (id)
);
]]

local MYSQL_CHAR_DATA = [[
CREATE TABLE IF NOT EXISTS `%s` (
    id INT UNSIGNED NOT NULL,
    key VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    PRIMARY KEY (id, key)
);
]]

local SQLITE_CHARACTER = [[
CREATE TABLE IF NOT EXISTS `%s` (
    id INTEGER PRIMARY KEY,
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
    id UNSIGNED INTEGER,
    key TEXT,
    value TEXT,
    PRIMARY KEY (id, key)
);
]]

-- Sets up the character table 
hook.Add("Initialize", "nutCharTableSetup", function()
    -- Set global variables for the character tables.
    CHARACTERS = engine.ActiveGamemode():lower().."_characters"
    CHAR_DATA = engine.ActiveGamemode():lower().."_chardata"
    print(engine.ActiveGamemode()) 
    -- Create the tables themselves.
    if (nut.db.sqlModule == nut.db.modules.sqlite) then
        nut.db.query(SQLITE_CHARACTER:format(CHARACTERS))
        nut.db.query(SQLITE_CHAR_DATA:format(CHAR_DATA))
    else
        nut.db.query(MYSQL_CHARACTER:format(CHARACTERS))
        nut.db.query(MYSQL_CHAR_DATA:format(CHAR_DATA))
    end
end)