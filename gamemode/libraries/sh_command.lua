--[[
File:    libraries/sh_command.lua
Purpose: Allows for chat and console commands to be easily set up.
--]]

nut.command = {}
nut.command.list = {}
nut.command.prefix = "nut"

-- The prefix for chat commands.
local COMMAND_PREFIX = "/"

-- The pattern for command names.
local COMMAND_PATTERN = "([_%w]+)"

-- The cooldown for processing commands from a player.
local COMMAND_COOLDOWN = 0.1

-- Where the arguments are after a command.
local ARGS_START = 2

-- Aways return true.
local ALWAYS_TRUE = function() return true end

-- Adds a command so it can be used.
function nut.command.add(name, info)
    assert(type(name) == "string", "name is not a string")
    assert(type(info) == "table", "info is not a table")
    assert(type(info.onRun) == "function", "'"..name.."' does not"..
           " have a onRun function")
    assert(name:match(COMMAND_PATTERN), "name can only contain"..
           " alphanumeric characters and underscores")

    -- Set up command permission shortcuts.
    if (type(info.onCanRun) ~= "function") then
        if (info.adminOnly) then
            info.onCanRun = function(client)
                return client:IsAdmin()
            end
        elseif (info.superAdminOnly) then
            info.onCanRun = function(client)
                return client:IsSuperAdmin()
            end
        elseif (type(info.group) == "string") then
            info.onCanRun = function(client)
                return client:IsUserGroup(info.group)
            end
        elseif (type(info.group) == "table") then
            info.onCanRun = function(client)
                -- Check each group in the list of groups.
                for _, group in ipairs(info.group) do
                    if (client:IsUserGroup(group)) then
                        return true
                    end
                end

                return false
            end
        else
            info.onCanRun = ALWAYS_TRUE
        end
    end

    -- Add the command.
    nut.command.list[name] = info

    hook.Run("CommandRegistered", name, info)
end

-- Returns whether or not a command can be ran by a player.
function nut.command.canRun(client, command)
    assert(type(command) == "string", "command is not a string")

    -- Get information about the given command.
    local info = nut.command.list[command]

    -- Don't run non-existent commands.
    if (not info) then
        return false
    end

    -- Check for server console access.
    if (not IsValid(client)) then
        return info.allowConsole == true
    end

    -- Delegate to the command's onCanRun.
    return info.onCanRun(client)
end


-- Converts a string into a list of arguments.
function nut.command.parseArgs(message)
    -- All the arguments found.
    local arguments = {}

    -- The current argument being parsed.
    local argument

    -- Which character to skip to.
    local skip = 0

    -- Parse each character of the message.
    for i = 1, #message do
        -- Ignore this character if skipping.
        if (i < skip) then
            continue
        end

        local character = message[i]

        if (character:match("%s")) then
            if (not argument) then
                continue
            end

            -- Separate arguments by whitespaces.
            arguments[#arguments + 1] = argument
            argument = nil
        elseif (character == "'" or character == "\"") then
            -- Whether or not we are done looking for arguments.
            local finished

            -- Set the argument to be a string surrounded by quotes.
            local match = message:sub(i):match("%b"..character..character)

            -- Don't parse the match.
            if (not match) then
                -- If no ending quote was found, let the match be the rest
                -- of the string and set the finished state to true since
                -- there will be nothing left to parse.
                match = message:sub(i + 1)
                finished = true
            else
                skip = i + #match + 1
                match = match:sub(ARGS_START, -ARGS_START)
            end

            -- Add the match as an argument.
            arguments[#arguments + 1] = match

            if (finished) then
                break
            end
        else
            -- This character is not special so just build up an argument.
            argument = (argument or "")..character
        end
    end

    -- Add the leftover argument if it exists.
    if (argument) then
        arguments[#arguments + 1] = argument
    end

    return arguments
end

if (SERVER) then
    util.AddNetworkString("nutCommand")

    -- Finds and runs a command from a given chat message.
    function nut.command.parse(speaker, message)
        -- Find the command from the message.
        local start, finish, name = message:find(COMMAND_PREFIX..
                                                 COMMAND_PATTERN)

        -- Check if the command was found at the beginning.
        if (start == 1 and name) then
            local command = nut.command.list[name]

            -- Check if there is information about the command.
            if (not command) then
                return false
            end

            -- Parse the arguments.
            local argumentString = string.TrimLeft(message:sub(ARGS_START))
            local arguments = nut.command.parseArgs(argumentString)

            -- Run the command.
            local status, reason = command.onRun(speaker, arguments)
            reason = reason or ""

            if (status == false) then
                hook.Run("CommandFailed", speaker, name, arguments, reason)
            else
                hook.Run("CommandRan", speaker, name, arguments)
            end

            hook.Run("CommandParsed", speaker, message)

            return true
        end
    end

    -- Runs a command for a player.
    function nut.command.run(client, command, ...)
        assert(type(command) == "string", "command is not a string")

        -- Check if the player can run the command.
        if (nut.command.canRun(client, command) == false) then
            return false, "not allowed"
        end

        local info = nut.command.list[command]

        -- Get the arguments from the varargs.
        local arguments = {}

        for _, argument in ipairs({...}) do
            arguments[#arguments + 1] = tostring(argument)
        end

        -- Run the command if it exists.
        if (info) then
            local status, reason = info.onRun(client, arguments)

            if (status == nil) then
                status = true
            end

            if (status == false) then
                hook.Run("CommandFailed", client, command, arguments, reason)
            else
                hook.Run("CommandRan", client, command, arguments)
            end

            return status, reason or ""
        end

        return false, "invalid command"
    end

    -- Receive commands from the client.
    net.Receive("nutCommand", function(length, client)
        -- Have a cooldown for running commands.
        if ((client.nutNextCommand or 0) < CurTime()) then
            client.nutNextCommand = CurTime() + COMMAND_COOLDOWN
        else
            return
        end

        -- Get the arguments from the client.
        local arguments = {}
        local command = net.ReadString()
        local count = net.ReadUInt(8)

        for i = 1, count do
            arguments[#arguments + 1] = net.ReadString()
        end

        -- Run the command.
        nut.command.run(client, command, unpack(arguments))
    end)

    -- Set up a console command for the registered commands.
    hook.Add("Initialize", "nutConsoleCommand", function()
        concommand.Add(nut.command.prefix, function(client, _, arguments)
            if (not arguments[1]) then
                return
            end

            nut.command.run(client, arguments[1],
                            unpack(arguments, ARGS_START))
        end)
    end)

    -- Log which commands are ran.
    hook.Add("CommandParsed", "nutCommandLog", function(client, message)
        if (not IsValid(client)) then
            return
        end

        ServerLog(client:Name().." ran '"..message.."'\n")
    end)
else
    -- Run a command for the local player.
    function nut.command.run(command, ...)
        local arguments = {...}

        net.Start("nutCommand")
            net.WriteString(command)
            net.WriteUInt(#arguments, 8)
            
            for i = 1, #arguments do
                net.WriteString(tostring(arguments[i]))
            end
        net.SendToServer()
    end
end
