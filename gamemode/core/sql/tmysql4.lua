--[[
File:    core/sql/sqlite.lua
Purpose: Provides an implementation for the NutScript database functions
         using SQLite.
--]]

-- The last occuring SQL error.
local lastError = ""

nut.db.modules.tmysql4 = {
    connect = function(callback)
        if (not tmysql) then
            require("tmysql4")
        end

        -- Create a connection.
        local object, reason = tmysql.Connect(nut.db.hostname,
                                              nut.db.username,
                                              nut.db.password,
                                              nut.db.database,
                                              nut.db.port)

        -- Check if the connection was successful or not.
        if (object) then
            nut.db.object = object
            hook.Run("DatabaseConnected")

            if (type(callback) == "function") then
                callback(true)
            end
        else
            nut.db.lastError = reason
            hook.Run("DatabaseConnectionFailed", reason)

            if (type(callback) == "function") then
                callback()
            end
        end
    end,
    query = function(value, callback)
        if (nut.db.object) then
            nut.db.object:Query(value, callback)
        elseif (type(callback) == "function") then
            callback()
        end
    end,
    escape = function(value)
        if (nut.db.object) then
            return nut.db.object:Escape(value)
        end

        return sql.SQLStr(value)
    end
}
