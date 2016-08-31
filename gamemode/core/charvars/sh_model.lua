--[[
File:    core/charvars/sh_model.lua
Purpose: Allows characters to be represented as a model in-game.
--]]

nut.char.registerVar("model", {
    default = "models/error.mdl",
    field = "model",
    onSet = function(character, value)
        local client = character:getPlayer()

        if (IsValid(client)) then
            client:SetModel(value)
            client:SetupHands()
        end
    end,
    onSetup = function(character, client)
        client:SetModel(character:getModel())
        client:SetupHands()
    end,
    replication = CHARVAR_PUBLIC
})