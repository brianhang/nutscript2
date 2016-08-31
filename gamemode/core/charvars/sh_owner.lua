--[[
File:    core/charvars/sh_owner.lua
Purpose: Keeps track of character ownership for players.
--]]

nut.char.registerVar("owner", {
    default = "",
    field = "steamID",
    onSet = function(character, steamID)
        -- Convert players to a 64-bit SteamID.
        if (type(steamID) == "Player") then
            if (not IsValid(steamID)) then
                error("The new owner is not a valid player")
            end

            steamID = steamID:SteamID64() or 0
        elseif (type(steamID) ~= "string") then
            error("The new owner must be a player or a string")
        end

        -- Remove the old owner.
        local oldOwner = character:getPlayer()

        if (IsValid(oldOwner) and oldOwner:getChar() == character) then
            character:kick()
        end

        hook.Run("CharacterTransferred", character, oldOwner, steamID)

        -- Update the database immediately.
        steamID = nut.db.escape(steamID)
        nut.db.query("UPDATE "..CHARACTERS.." SET steamID = "..steamID..
                     " WHERE id = "..character:getID())

        -- Override owner to be the SteamID if it was a player.
        return true, steamID
    end,
    onSave = CHARVAR_NOSAVE,
    replication = CHARVAR_PUBLIC
})