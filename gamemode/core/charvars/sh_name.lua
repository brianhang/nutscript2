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

-- Have players' name return their character's name.
local PLAYER = FindMetaTable("Player")

-- Allow for their Steam name to still be accessed.
PLAYER.steamName = PLAYER.steamName or PLAYER.Name
PLAYER.SteamName = PLAYER.steamName

-- Micro-optimizations for getting the name.
local charGetName = nut.meta.character.getName
local steamName = PLAYER.steamName

-- Return the character's name if there is one.
function PLAYER:Name()
    local character = self.getChar(self)

    return character and charGetName(character) or steamName(self)
end

-- Have Nick and GetName do the same.
PLAYER.Nick = PLAYER.Name
PLAYER.GetName = PLAYER.Name