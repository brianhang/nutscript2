--[[
File:    sh_team.lua
Purpose: Provides an easier interface for creating and managing teams.
--]]

nut.team = {}
nut.team.list = {}
nut.team.classes = {}

-- Loads a team from a path to a file.
function nut.team.load(path)
    -- Create a table to store team information.
    TEAM = {}
    
    -- Include the team's file.
    nut.util.include(path, "shared")
    
    assert(type(TEAM.id) == "number", "team ID not set ("..path..")")
    assert(type(TEAM.name) == "string", "team is missing name ("..path..")")
    assert(type(TEAM.color) == "table", "team is missing color ("..path..")")

    -- Register the team.
    team.SetUp(TEAM.id, TEAM.name, TEAM.color)
    nut.team.list[TEAM.id] = TEAM

    TEAM = nil
end

-- Loads a class from a path to a file.
function nut.team.loadClass(path)
    -- Create a table to store class information.
    CLASS = {}

    -- Include the class's file.
    nut.util.include(path, "shared")

    assert(type(CLASS.id) == "number", "class ID is not a number")
    assert(type(CLASS.name) == "string", "class name is not a string")
    assert(type(CLASS.team) == "number", "class team is not a number"..
           " ("..path..")")
    assert(team.Valid(CLASS.team), "class team is not a valid team"..
           " ("..path..")")

    -- Register the class.
    nut.team.classes[CLASS.id] = CLASS

    CLASS = nil
end

-- Loads classes and teams from a given directory.
function nut.team.loadFromDir(base)
    for _, path in ipairs(file.Find(base.."/teams/*.lua", "LUA")) do
        nut.team.load(base.."/teams/"..path)
    end

    for _, path in ipairs(file.Find(base.."/classes/*.lua", "LUA")) do
        nut.team.loadClass(base.."/classes/"..path)
    end
end

if (SERVER) then
    -- Sets up the loadout for a team member.
    function nut.team.loadout(client, teamID)
        assert(type(client) == "Player", "client is not a player")
        assert(IsValid(client), "client is not a valid player")

        -- Get information about the team that the player is in.
        local info = nut.team.list[client:Team()]

        if (not info) then
            return false
        end

        -- Get information about the class that the player is in.
        local character = client:getChar()

        if (character) then
            local classInfo = nut.team.classes[character:getClass()]

            -- Merge the class variables with the team variables.
            if (classInfo and classInfo.team == teamID) then
                info = table.Copy(info)
                table.Merge(info, classInfo)
            end
        end
        
        -- Give weapons from the loadout.
        if (type(info.loadout) == "table") then
            for _, item in pairs(info.loadout) do
                client:Give(item)
            end
        end

        -- Set the various team parameters.
        client:SetHealth(info.health or client:Health())
        client:SetMaxHealth(info.maxHealth or client:GetMaxHealth())
        client:SetArmor(info.armor or client:Armor())
        client:SetRunSpeed(info.runSpeed or client:GetRunSpeed())
        client:SetWalkSpeed(info.walkSpeed or client:GetWalkSpeed())

        -- Run the onLoadout callback.
        if (type(info.onLoadout) == "function") then
            info:onLoadout(client)
        end

        return true
    end

    -- Implement the team loadout.
    hook.Add("PlayerLoadout", "nutTeamLoadout", function(client)
        nut.team.loadout(client, client:Team())
    end)
end