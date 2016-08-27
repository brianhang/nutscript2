--[[
File:    libraries/sv_database.lua
Purpose: Creates the functions responsible for managing characters between
         the server and the database.
--]]

if (not nut.char) then
    nut.util.include("sh_character.lua")
end

if (not nut.db) then
    nut.util.include("sv_database.lua")
end

util.AddNetworkString("nutCharData")
util.AddNetworkString("nutCharDelete")
util.AddNetworkString("nutCharTempVar")
util.AddNetworkString("nutCharVar")

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
    data.steamID = info.steamID or "0"
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
function nut.char.load(id, callback, reload)
    assert(type(id) == "number", "id is not a number")
    assert(id >= 0, "id can not be negative")

    -- Don't load the character if it already exists.
    if (not reload and nut.char.list[id]) then
        if (type(callback) == "function") then
            callback(nut.char.list[id])
        end

        return
    end

    -- The character that contains the results of loading.
    local character

    -- Get the fields that are needed to load the character.
    local fields = {}

    for name, variable in pairs(nut.char.vars) do
        if (variable.field) then
            fields[#fields + 1] = variable.field
        end
    end

    -- Load the data from the database.
    nut.db.select(CHARACTERS, fields, "id = "..id, function(result)
        if (result and result[1]) then
            result = result[1]
            
            -- Create a character object to store the results.
            character = nut.char.new(id)

            -- Load variables from the results.
            for name, variable in pairs(nut.char.vars) do
                local field = variable.field
                local value = result[field]

                -- Allow for custom loading of this variable.
                if (type(variable.onLoad) == "function") then
                    variable.onLoad(character)

                    continue
                end
                
                -- Convert the string value to the correct Lua type.
                if (variable.default and field and value) then
                    -- Get the suggested type.
                    local defaultType = type(variable.default)

                    -- Convert to the suggested type if applicable.
                    if (ENCODE_TYPES[defaultType]) then
                        local status, result = pcall(pon.decode, value)

                        if (status) then
                            value = result[1]
                        else
                            ErrorNoHalt("Failed to decode "..name.." for "..
                                        "character #"..id..".\n")
                        end
                    elseif (defaultType == "number") then
                        value = tonumber(value)
                    elseif (defaultType == "boolean") then
                        value = tobool(value)
                    end
                end

                -- Store the retrieved value.
                if (field) then
                    character.vars[name] = value
                end
            end

        else
            ErrorNoHalt("Failed to load character #"..id.."\n"..
                        nut.db.lastError.."\n")
        end

        -- Run the callback if one is given.
        if (type(callback) == "function") then
            callback(character)
        end
    end, 1)
end

-- The queries needed to create tables for NutScript characters.
local MYSQL_CHARACTER = [[
CREATE TABLE IF NOT EXISTS `%s` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(70) NOT NULL,
    `desc` TEXT,
    `model` VARCHAR(160) NOT NULL,
    `createTime` INT(11) UNSIGNED NOT NULL,
    `lastJoin` INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `money` INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `team` TINYINT(4) UNSIGNED,
    `steamID` BIGINT(20) UNSIGNED NOT NULL,
    PRIMARY KEY (`id`)
) AUTO_INCREMENT=1;
]]

local MYSQL_CHAR_DATA = [[
CREATE TABLE IF NOT EXISTS `%s` (
    `id` INT UNSIGNED NOT NULL,
    `key` VARCHAR(65) NOT NULL,
    `value` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`id`, `key`)
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
hook.Add("DatabaseConnected", "nutCharTableSetup", function()
    -- Set global variables for the character tables.
    CHARACTERS = engine.ActiveGamemode():lower().."_characters"
    CHAR_DATA = engine.ActiveGamemode():lower().."_chardata"

    -- Create the tables themselves.
    if (nut.db.sqlModule == nut.db.modules.sqlite) then
        nut.db.query(SQLITE_CHARACTER:format(CHARACTERS))
        nut.db.query(SQLITE_CHAR_DATA:format(CHAR_DATA))
    else
        nut.db.query(MYSQL_CHARACTER:format(CHARACTERS))
        nut.db.query(MYSQL_CHAR_DATA:format(CHAR_DATA))
        print("Done")
    end
end)
