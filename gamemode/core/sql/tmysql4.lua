--[[
File:    core/sql/sqlite.lua
Purpose: Provides an implementation for the NutScript database functions
         using SQLite.
--]]

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
            nut.db.object:Query(value, function(results)
                local result = results[1]
                local data

                if (result.status) then
                    data = result.data
                    nut.db.lastID = result.lastid
                else
                    ErrorNoHalt("Query failed! ("..value..")\n")
                    ErrorNoHalt(result.error.."\n")

                    nut.db.lastError = result.error
                end

                if (type(callback) == "function") then
                    callback(data)
                end
            end)
        elseif (type(callback) == "function") then
            callback()
        end
    end,
    escape = function(value)
        if (nut.db.object) then
            return nut.db.object:Escape(value)
        end

        return sql.SQLStr(value, true)
    end,
    getInsertID = function()
        return nut.db.lastID
    end
}
