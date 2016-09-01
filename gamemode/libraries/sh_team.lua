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
