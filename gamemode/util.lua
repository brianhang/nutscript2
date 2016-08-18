--[[
File:    util.lua
Purpose: Sets up the utility "library" by providing the utility function to
         load files and folders. Then, the actual utility functions are
         included.
--]]

-- The character before the trailing slash of a path.
local BEFORE_SLASH = -2

nut.util = nut.util or {}

-- Includes a file with handling of state using the file's name.
function nut.util.include(path, state)
    if (state == "server" or path:find("sv_") and SERVER) then
        return include(path)
    elseif (state == "client" or path:find("cl_")) then
        if (SERVER) then
            AddCSLuaFile(path)
        else
            return include(path)
        end
    elseif (state == "shared" or path:find("sh_")) then
        if (SERVER) then
            AddCSLuaFile(path)
        end

        return include(path)
    end
end

-- Includes files within a folder with handling of state.
function nut.util.includeDir(directory, state, relative)
    -- Get where to start searching for files from.
    local baseDir

    if (relative) then
        baseDir = ""
    else
        local gamemode = GM and GM.FolderName or engine.ActiveGamemode()
                         or "nutscript2"

        baseDir = gamemode.."/gamemode/"
    end

    -- Remove the trailing slash if it exists.
    if (directory:sub(-1, -1) == "/") then
        directory = directory:sub(1, TRAILING_SLASH)
    end

    -- Include all files within the directory.
    for _, path in ipairs(file.Find(baseDir..directory.."/*.lua", "LUA")) do
        nut.util.include(baseDir..directory.."/"..path, state)
    end
end

-- Include the utility functions.
nut.util.includeDir("util")
