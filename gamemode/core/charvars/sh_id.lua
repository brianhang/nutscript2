--[[
File:    core/charvars/sh_id.lua
Purpose: Adds a numeric identifier for a character.
--]]

nut.char.registerVar("id", {
    field = "id",
    isConstant = true,
    onSave = CHARVAR_NOSAVE,
    replication = CHARVAR_NONE
})