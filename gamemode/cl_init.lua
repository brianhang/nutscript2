--[[
File:    cl_init.lua
Purpose: Loads the client-side portion of NutScript.
--]]

-- Set up the NutScript "namespace".
nut = nut or {}

-- Include shared.lua to load all the framework files then setup.lua to set up
-- the gamemode for use.
include("shared.lua")
