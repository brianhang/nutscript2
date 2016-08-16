--[[
File:    shared.lua
Purpose: Loads all of the NutScript framework components.
--]]

DeriveGamemode("sandbox")

-- Include utility functions.
include("util.lua")

-- Include the framework files.
nut.util.includeDir("thirdparty")
nut.util.includeDir("libraries")

-- Set some gamemode information.
GM.Name = "NutScript 2"
GM.Author = "Chessnut"

-- Loads the framework related files within the derived gamemode.
function GM:PostGamemodeLoaded()
    nut.plugin.initialize()
end

-- Loads the framework related files after a refresh occured.
function GM:OnReloaded()
    nut.plugin.initialize()
end