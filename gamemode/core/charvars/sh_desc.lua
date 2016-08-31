--[[
File:    core/charvars/sh_desc.lua
Purpose: Adds a physical description of a character.
--]]

nut.char.registerVar("desc", {
    default = "",
    field = "desc",
    replication = CHARVAR_PUBLIC
})