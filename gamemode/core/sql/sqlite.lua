--[[
File:    core/sql/sqlite.lua
Purpose: Provides an implementation for the NutScript database functions
         using SQLite.
--]]

nut.db.modules.sqlite = {
    connect = function(callback)
        -- No actual connection needed.
        if (type(callback) == "function") then
            callback(true)
        end
    end,
    query = function(value, callback)
        local result = sql.Query(value)

        if (result ~= false) then
            -- Run the callback with the given results.
            if (type(callback) == "function") then
                callback(result or {})
            end
        else
            -- If there was an error, store it and run the callback with
            -- no results.
            nut.db.lastError = sql.LastError()

            if (type(callback) == "function") then
                callback()
            end
        end
    end,
    escape = function(value)
        return sql.SQLStr(value, true)
    end,
    getInsertID = function()
        return tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
    end
}
