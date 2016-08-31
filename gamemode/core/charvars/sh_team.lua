--[[
File:    core/charvars/sh_team.lua
Purpose: Allows characters to be associated with certain teams.
--]]

nut.char.registerVar("team", {
    default = 0,
    field = "team",
    onSet = function(character, value)
        local client = character:getPlayer()

        if (IsValid(client)) then
            client:SetTeam(value)
        end
    end,
    onSetup = function(character, client)
        if (team.Valid(character:getTeam())) then
            client:SetTeam(character:getTeam())
        end
    end,
    replication = CHARVAR_PUBLIC
})
