-- Regular chat configuration.
local CHAT_COLOR = Color(255, 239, 150)
local CHAT_INDICATOR = Color(250, 50, 50)

-- Scaling for the whisper color and range respectively.
local SCALE_WHISPER = 0.8
local SCALE_WHISPER_RANGE = 0.5

-- Scaling for yelling color and range.
local SCALE_YELL = 1.33
local SCALE_YELL_RANGE = 1.75

-- The second character in a message.
local MSG_START = 2

-- Regular local chat
nut.chat.register("ic", {
    color = CHAT_COLOR,
    range = 280
})

-- Player action
nut.chat.register("me", {
    color = CHAT_COLOR,
    range = nut.chat.modes.ic.range,
    onChatAdd = function(speaker, message, context)
        local name = hook.Run("GetChatName", speaker, context) or
                     speaker:Name()

        chat.AddText(CHAT_COLOR, "**"..name.." "..message)
    end,
    prefix = {"/me", "/action"}
})

-- Local action
nut.chat.register("it", {
    color = CHAT_COLOR,
    range = nut.chat.modes.ic.range,
    onChatAdd = function(speaker, message, context)
        chat.AddText(CHAT_COLOR, "**"..message:sub(MSG_START))
    end
})

-- Whisper
nut.chat.register("w", {
    color = Color(CHAT_COLOR.r * SCALE_WHISPER, CHAT_COLOR.g * SCALE_WHISPER,
                  CHAT_COLOR.g * SCALE_WHISPER),
    range = nut.chat.modes.ic.range * SCALE_WHISPER_RANGE,
    prefix = {"/w", "/whisper"}
})

-- Yelling
nut.chat.register("y", {
    color = Color(CHAT_COLOR.r * SCALE_YELL, CHAT_COLOR.g * SCALE_YELL,
                  CHAT_COLOR.b * SCALE_YELL),
    range = nut.chat.modes.ic.range * SCALE_YELL_RANGE,
    prefix = {"/y", "/yell"}
})

-- Global out-of-character
nut.chat.register("ooc", {
    prefix = {"//", "/ooc"},
    noSpaceAfter = true,
    onChatAdd = function(speaker, message, context)
        chat.AddText(CHAT_INDICATOR, "[OOC] ", speaker, color_white,
                     ": "..message)
    end
})

-- Local out-of-character
nut.chat.register("looc", {
    range = nut.chat.modes.ic.range,
    prefix = {".//", "[[", "/looc"},
    noSpaceAfter = true,
    onChatAdd = function(speaker, message, context)
        chat.AddText(CHAT_INDICATOR, "[LOOC] ", CHAT_COLOR,
                     speaker:Name()..": "..message)
    end
})
