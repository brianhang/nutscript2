--[[
File:    libraries/sv_database.lua
Purpose: Allows for easy access to a database so one can store and load
         information.
--]]

-- Types of values that can be encoded using pON.
ENCODE_TYPES = {}
ENCODE_TYPES["Angle"] = true
ENCODE_TYPES["Vector"] = true
ENCODE_TYPES["table"] = true

-- The default MySQL port.
local DEFAULT_PORT = 3306

nut.db = nut.db or {}
nut.db.lastError = nut.db.lastError or ""
nut.db.modules = {}

-- Include SQL module implementations.
nut.util.includeDir("core/sql", "server")

-- Connects to a database using the given module.
function nut.db.connect(sqlModule, callback)
    assert(type(sqlModule) == "table", "sqlModule is not a table")
    assert(type(sqlModule.connect) == "function",
           "sqlModule is missing a connect function")
    assert(type(sqlModule.query) == "function",
           "sqlModule is missing a query function")
    assert(type(sqlModule.escape) == "function",
           "sqlModule is missing a escape function")
    assert(type(sqlModule.getInsertID) == "function",
           "sqlModule is missing a getInsertID function")

    -- Check to see connection details are provided, if needed.
    if (sqlModule.needsDetails) then
        assert(nut.db.hostname, "nut.db.hostname is not set")
        assert(nut.db.username, "nut.db.username is not set")
        assert(nut.db.password, "nut.db.password is not set")
        assert(nut.db.database, "nut.db.database is not set")

        nut.db.port = tonumber(nut.db.port) or DEFAULT_PORT
    end

    -- Set the nut.db functions to correspond to sqlModule's.
    nut.db.query = sqlModule.query
    nut.db.escape = sqlModule.escape
    nut.db.getInsertID = sqlModule.getInsertID
    nut.db.sqlModule = sqlModule

    -- Connect to the database if applicable.
    sqlModule.connect(callback)
end

-- Deletes rows within the database under given conditions.
function nut.db.delete(tableName, condition, callback, limit)
    -- Start the deletion query.
    local query = "DELETE FROM "..tostring(tableName)

    -- Add a condition if one was given.
    if (condition) then
        query = " WHERE "..tostring(condition)
    end

    -- Add a limit if one was given.
    if (limit) then
        query = " LIMIT "..tostring(limit)
    end

    nut.db.query(query, callback)
end

-- Makes a string safer for queries.
nut.db.escape = sql.SQLStr

-- Returns the index of the last inserted row.
function nut.db.getInsertID()
    error("nut.db.getInsertID has not been overwritten!")
end

-- Inserts given values into the given table.
function nut.db.insert(tableName, data, callback)
    assert(type(data) == "table", "data is not a table")

    -- Get the start of the insert query.
    local query = "INSERT INTO "..tostring(tableName)

    -- Convert the table into columns and values.
    local columns = {}
    local values = {}

    for k, v in pairs(data) do
        columns[#columns + 1] = tostring(k)
        values[#values + 1] = nut.db.toString(v)
    end
    
    -- Do nothing if the table is empty.
    if (#columns == 0) then
        return
    end

    -- Put the columns and values into the insert query.
    query = query.." ("..table.concat(columns, ",")..") VALUES ("..
            table.concat(values, ",")..")"

    -- Run the generated query.
    nut.db.query(query, callback)
end

-- Does a raw query to the database.
function nut.db.query(query, callback)
    error("nut.db.query has not been overwritten!")
end

-- Selects given fields in a given table.
function nut.db.select(tableName, fields, condition, callback, limit, order)
    -- Convert fields into a string list of fields.
    if (type(fields) == "table") then
        -- Do nothing if no fields are desired.
        if (#fields == 0) then
            return
        end

        fields = table.concat(fields, ",")
    else
        fields = "*"
    end

    -- Start generating the query.
    local query = "SELECT "..fields.." FROM "..tostring(tableName)

    -- Add a where clause if needed.
    if (condition) then
        query = query.." WHERE "..tostring(condition)
    end

    -- Order the results if an order is given.
    if (order) then
        query = query.." ORDER BY "..tostring(order)
    end

    -- Add a limit if one is given.
    if (limit) then
        query = query.." LIMIT "..limit
    end

    nut.db.query(query, callback)
end

-- Converts a Lua value into an escaped string for the database.
function nut.db.toString(value, noQuotes)
    -- The type of value.
    local valueType = type(value)

    -- Handle certain types of values.
    if (valueType == "boolean") then
        return value and "1" or "0"
    elseif (ENCODE_TYPES[valueType]) then
        local output = nut.db.escape(pon.encode({value}))

        if (not noQuotes) then
            output = "\""..output.."\""
        end

        return output
    elseif (valueType == "string") then
        local output = nut.db.escape(value)

        if (not noQuotes) then
            output = "\""..output.."\""
        end

        return output
    end

    -- Default to just converting the value to a string.
    return tostring(value)
end

-- Updates values within a table.
function nut.db.update(tableName, data, condition, callback, limit)
    assert(type(data) == "table", "data is not a table")

    -- Start generating the query.
    local query = "UPDATE "..tostring(tableName).." SET "

    -- Convert the table into an update query.
    local updates = {}

    for k, v in pairs(data) do
        updates[#updates + 1] = tostring(k).."="..nut.db.toString(v)
    end

    -- Don't do anything if data is empty.
    if (#updates == 0) then
        return
    end

    -- Add the columns and values to the query.
    query = query.." SET "..table.concat(updates, ",")

    -- Add the condition if given.
    if (conditon) then
        query = query.." WHERE "..tostring(condition)
    end

    -- Add the limit if given.
    if (limit) then
        query = query.." LIMIT "..tostring(limit)
    end

    nut.db.query(query, callback)
end

-- Default to SQLite.
nut.db.connect(nut.db.modules.sqlite)
