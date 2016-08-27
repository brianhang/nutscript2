--[[
File:    libraries/sh_currency.lua
Purpose: Creates a system for storing information about the gamemode's main
         currency.
--]]

-- The money entity to use.

nut.currency = {}
nut.currency.plural = "dollars"
nut.currency.singular = "dollar"
nut.currency.symbol = "$"
nut.currency.entity = "nut_money"

-- Sets the currency for the gamemode.
function nut.currency.set(symbol, singular, plural)
    assert(type(symbol) ~= "string" and type(singular) ~= "string",
           "either symbol or singular needs to be given")

    nut.currency.symbol = symbol or ""
    nut.currency.singular = singular or ""
    nut.currency.plural = plural or singular

    -- Overwrite the toString to get the correct string format.
    if (symbol) then
        -- Set the toString to only use a symbol.
        function nut.currency.toString(amount)
            return symbol..amount
        end
    else
        -- If a symbol is not given, use the word form.
        if (not plural) then
            plural = singular
        end

        function nut.currency.toString(amount)
            return amount.." "..(amount == 1 and singular or plural)
        end
    end
end

-- Returns the string version of a given amount of money.
function nut.currency.toString(value)
    return value
end

if (SERVER) then
    -- Spawns a money entity containing the given amount.
    function nut.currency.spawn(position, amount, setAmountFuncName)
        assert(type(position) == "Vector", "position is not a vector")
        assert(type(amount) == "number", "amount is not a number")

        if (type(setAmountFuncName) ~= "string") then
        	setAmountFuncName = "SetAmount"
        end

        local entity = ents.Create(nut.currency.entity)
        entity:SetPos(position)
        entity:Spawn()
        entity[setAmountFuncName](entity, amount)

        hook.Run("MoneySpawned", entity)

        return entity        
    end
end

-- Add the character extensions here.
if (not nut.meta.character) then
    nut.util.include("nutscript2/gamemode/classes/sh_character.lua")
end

local CHARACTER = nut.meta.character

-- Gives the character a certain amount of money.
function CHARACTER:giveMoney(amount)
    self:setMoney(self:getMoney() + amount)
end

-- Takes a certain amount of money away from a character.
function CHARACTER:takeMoney(amount)
    self:setMoney(self:getMoney() - amount)
end
