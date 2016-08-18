--[[
File:    libraries/sv_database.lua
Purpose: Allows for easy access to a database so one can store and load
         information.
--]]

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
    nut.db.sqlModule = sqlModule

    -- Connect to the database if applicable.
    sqlModule.connect(callback)
end

-- Deletes rows within the database under given conditions.
function nut.db.delete(tableName, condition, callback, limit)
    assert(type(tableName) == "string", "tableName is not a string")

    -- Start the deletion query.
    local query = "DELETE FROM `"..tableName.."`"

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
    return 0
end

-- Inserts given values into the given table.
function nut.db.insert(tableName, data, callback)
    error("nut.db.insert has not been overwritten!")
end

-- Does a raw query to the database.
function nut.db.query(query, callback)
    error("nut.db.query has not been overwritten!")
end

-- Selects given fields in a given table.
function nut.db.select(tableName, fields, condition, callback, order)
    error("nut.db.select has not been overwritten!")
end

-- Updates values within a table.
function nut.db.update(tableName, data, condition, callback, limit)
    error("nut.db.update has not been overwritten!")
end

-- Default to SQLite.
nut.db.connect(nut.db.modules.sqlite)
