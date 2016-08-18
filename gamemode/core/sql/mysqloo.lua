--[[
File:    core/sql/mysqloo.lua
Purpose: Provides an implementation for the NutScript database functions
         using mysqloo.
--]]

-- The position of the query within a queued query.
local QUEUE_QUERY = 1

-- The position of the callback within a queued query.
local QUEUE_CALLBACK = 2

-- A list of queries to run after a connection is restarted.
nut.db.queryQueue = nut.db.queryQueue or {}

nut.db.modules.mysqloo = {
    connect = function(callback)
        -- Open a database connection.
        if (not mysqloo) then
            require("mysqloo")
        end

        local object = mysqloo.connect(nut.db.hostname, nut.db.username,
                                       nut.db.password, nut.db.database,
                                       nut.db.port)

        function object:onConnected()
            hook.Run("DatabaseConnected")

            if (type(callback) == "function") then
                callback(true)
            end

            -- Run old queues.
            for _, query in ipairs(nut.db.queryQueue) do
                nut.db.query(query[QUEUE_QUERY], query[QUEUE_CALLBACK])
            end

            nut.db.queryQueue = {}
        end

        function object:onConnectionFailed(reason)
            nut.db.lastError = reason
            hook.Run("DatabaseConnectionFailed")

            if (type(callback) == "function") then
                callback()
            end
        end

        -- Start the connection.
        object:connect()

        -- Store the database connection.
        nut.db.object = object
    end,
    query = function(value, callback)
        if (nut.db.object) then
            local query = nut.db.object:query(value)

            function query:onSuccess(data)
                callback(data)
            end

            function query:onError(reason)
                -- Reconnect if the connection timed out.
                if (reason:find("has gone away")) then
                    -- Queue the query.
                    nut.db.queryQueue[#nut.db.queryQueue + 1] = {value,
                                                                 callback}

                    -- Reconnect to the database.
                    nut.db.object:abortAllQueries()
                    nut.db.modules.mysqloo.connect()
                else
                    nut.db.lastError = reason
                    callback()
                end
            end

            query:start()
        elseif (type(callback) == "function") then
            callback()
        end
    end,
    escape = function(value)
        if (nut.db.object) then
            return nut.db.object:escape(value)
        end

        return sql.SQLStr(value)
    end
}
