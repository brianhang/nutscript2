--[[
File:    libraries/sh_data.lua
Purpose: Creates functions for making it easier to store abitrary and persistent
         data.
--]]

-- The character after the curly brace.
local ENCODED_START = 2

-- The character before the closing curly brace.
local ENCODED_END = -2

nut.data = nut.data or {}
nut.data.stored = nut.data.stored or {}
nut.data.global = nut.data.global or {}

-- Sets a persistent data value.
function nut.data.set(key, value, ignoreMap, global)
    -- Find where the data should be stored.
    local store = global and nut.data.global or nut.data.stored
    local path = "nutscript2/"

    if (not global) then
        path = path..engine.ActiveGamemode().."/"
    end

    if (ignoreMap) then
        store["*"] = store["*"] or {}
        store = store["*"]
    else
        local map = game.GetMap()

        store[map] = store[map] or {}
        store = store[map]

        path = path..map.."/"
    end

    -- Set the data value.
    store[key] = value

    -- Write the value to disk.
    path = path..key..".txt"

    if (value == nil) then
        file.Delete(path)
    else
        local encoded = pon.encode({value})
        encoded = encoded:sub(ENCODED_START, ENCODED_END)

        file.Write(path, encoded)
    end
end

-- Reads a NutScript data value.
function nut.data.get(key, default, ignoreMap, global, refresh)
    -- Find where the data should be stored.
    local store = global and nut.data.global or nut.data.stored
    local path = "nutscript2/"

    if (not global) then
        path = path..engine.ActiveGamemode().."/"
    end

    if (ignoreMap) then
        store["*"] = store["*"] or {}
        store = store["*"]
    else
        local map = game.GetMap()

        store[map] = store[map] or {}
        store = store[map]

        path = path..map.."/"
    end

    -- Try reading the data from memory.
    if (not refresh and store[key] ~= nil) then
        return store[key]
    end

    -- Get the file containing the data.
    path = path..key..".txt"

    -- Read the value from disk.
    local encoded = file.Read(path, "DATA")

    -- Decode the encoded data.
    if (encoded) then
        local status, result = pcall(pon.decode, "{"..encoded.."}")

        if (status) then
            result = result[1]

            -- Store the decoded value in memory.
            store[key] = result

            return result
        end
    end

    return default
end

-- Set up the folder structure for NutScript data.
hook.Add("Initialize", "nutDataStore", function()
    local name = engine.ActiveGamemode():lower()

    file.CreateDir("nutscript2")
    file.CreateDir("nutscript2/"..name)
    file.CreateDir("nutscript2/"..name.."/"..game.GetMap())
end)
