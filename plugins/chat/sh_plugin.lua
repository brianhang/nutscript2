PLUGIN.name = "Roleplay Chat"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds basic roleplay chat modes."

nut.util.include("sh_modes.lua")

if (SERVER) then
    -- Called when a player is saying something.
    function PLUGIN:PlayerSay(speaker, message)
        -- Allow other hooks to override chat parsing.
        if (hook.Run("PrePlayerSay", speaker, message) == false) then
            return ""
        end
        -- Parse the chat message.
        if (nut.chat.send(speaker, message)) then
            return ""
        end
    end

    -- Called when the chat mode can be changed.
    function PLUGIN:ChatAdjustMode(speaker, mode, message, context)
        -- Default the mode to IC.
        if (mode == "") then
            return "ic"
        end
    end
end