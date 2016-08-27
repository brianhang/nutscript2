--[[
File:    init.lua
Purpose: Loads the server-side portion of NutScript.
--]]

-- Set up the NutScript "namespace".
nut = nut or {}

-- Include shared.lua to load all the framework files then setup.lua to set up
-- the gamemode for use.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("util.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
