--[[
File:    libraries/sh_chat.lua
Purpose: Sets up a system to divide chat messages into different types.
--]]

nut.chat = {}
nut.chat.modes = {}

-- The first character after a chat mode prefix.
local MSG_START = 2

-- A function that always returns true.
local ALWAYS_TRUE = function() return true end

-- Gets a list of players that can receive a certain chat.
function nut.chat.getRecipients(speaker, mode, message, context)
    assert(type(speaker) == "Player", "speaker is not a player")
    assert(IsValid(speaker), "speaker is not a valid player")

    -- Default context to an empty table.
    context = context or {}

    -- Get information about the chat mode.
    local info = nut.chat.modes[mode]

    -- A list of players that can hear the speaker.
    local recipients = {speaker}

    if (not info) then
        return recipients
    end

    -- Find which players can hear the speaker.
    for _, listener in ipairs(player.GetAll()) do
        if (mode.onCanHear(speaker, listener, message, context) or
            hook.Run("IsChatRecipient", speaker, listener, mode,
            message, context)) then
            recipients[#recipients + 1] = listener
        end
    end

    return recipients
end

-- Determines the type of chat message being sent from a given message.
function nut.chat.parse(speaker, message)
    assert(type(speaker) == "Player", "speaker is not a player")
    assert(IsValid(speaker), "speaker is not a valid player")
    assert(type(message) == "string")

    -- A table to store information about the chat message.
    local mode
    local context = {}

    -- Find the chat mode that matches.
    for thisMode, info in pairs(nut.chat.modes) do
        local prefix = info.prefix
        local offset = info.noSpaceAfter and 0 or 1
        local noSpaceAfter = info.noSpaceAfter

        -- Check if the prefix for this chat mode matches the one in
        -- the chat message.
        if (type(prefix) == "table") then
            -- If the prefix has aliases, check those as well.
            for _, alias in pairs(prefix) do
                if (message:sub(1, #alias + offset) ==
                    alias..(noSpaceAfter and "" or " ")) then
                    mode = thisMode
                    prefix = alias

                    break
                end
            end
        elseif (type(prefix) == "string" and message:sub(1, #prefix + offset)
                == prefix..(noSpaceAfter and "" or " ")) then
                mode = thisMode

                break
        end

        -- Change the message to only contain the real chat message.
        if (mode == thisMode) then
            message = message:sub(#prefix + 1)

            -- Get rid of the space in front if needed.
            if (not noSpaceAfter) then
                message = message:sub(MSG_START)
            end
        end
    end

    -- Default the chat mode to unknown.
    mode = mode or "unknown"
    
    -- Adjust the mode, context, and message.
    mode = hook.Run("ChatAdjustMode", speaker, message, mode, context) or mode
    hook.Run("ChatAdjustContext", speaker, mode, message, context)

    return mode, messasge, context
end

-- Sets up a chat mode for use in the future.
function nut.chat.register(mode, info)
    mode = tostring(mode)
    assert(type(info) == "table", "info for '"..mode.."' is not a table")

    -- Convert the canHear function into one that returns whether or not
    -- a player can be heard as a boolean.
    if (type(info.onCanHear) == "number") then
        local range = info.onCanHear

        info.onCanHear = function(speaker, listener)
            return speaker:GetPos():Distance(listener:GetPos()) <= range
        end
    else
        info.onCanHear = ALWAYS_TRUE
    end

    -- Default the onCanSay to always return true.
    info.onCanSay = info.onCanSay or ALWAYS_TRUE

    -- Default the adding chat to the chatbox to using a format and color.
    if (CLIENT and type(info.onChatAdd) ~= "function") then
        info.color = info.color or color_white
        info.format = info.format or "%s: %s"

        -- Create a function to add the message to the chatbox.
        info.onChatAdd = function(speaker, message, context)
            local name = hook.Run("ChatGetName", speaker, message, context) or
                         speaker:Name()        

            chat.AddText(info.color, info.format:format(name, message))
        end
    end

    -- Store the chat mode.
    nut.chat.modes[mode] = info
end

-- Sends a chat message using a given mode.
function nut.chat.send(speaker, message)
    assert(type(speaker) == "Player", "speaker is not a player")
    assert(IsValid(speaker), "speaker is not a valid player")
    assert(type(message) == "string", "message is not a string")

    -- Find the chat mode.
    local mode, message, context = nut.chat.parse(speaker, message)

    -- If one was not found, return false since the message will not
    -- be sent.
    if (not nut.chat.modes[mode]) then
        return false
    end

    -- Allow for final adjustments to the message.
    message = hook.Run("ChatMessageAdjust", speaker, mode, message)

    -- Network the chat message.
    local recipients = nut.chat.getRecipients(speaker, mode, message, context)

    if (#recipients > 0) then
        net.Start("nutChatMsg")
            net.WriteEntity(speaker)
            net.WriteString(mode)
            net.WriteString(message)
            net.WriteTable(context)
        net.Send(recipients)
    end
end

if (SERVER) then
    util.AddNetworkString("nutChatMsg")
else
    net.Receive("nutChatMsg", function()
        local speaker = net.ReadEntity()
        local mode = net.ReadString()
        local message = net.ReadString()
        local context = net.ReadTable()
        local info = nut.chat.modes[mode]

        if (info) then
            info.onChatAdd(speaker, message, context)
        end
    end)
end
