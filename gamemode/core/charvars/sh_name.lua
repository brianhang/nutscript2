--[[
File:    core/charvars/sh_name.lua
Purpose: Adds a name for characters.
--]]

nut.char.registerVar("name", {
    default = "",
    field = "name",
    replication = CHARVAR_PUBLIC,
    notNull = true
})