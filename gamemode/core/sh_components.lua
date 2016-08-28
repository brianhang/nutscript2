--[[
File:    core/sh_components.lua
Purpose: Sets up plugin components for the built in libraries included with
         Nutscript.
--]]

-- For file names without the extension.
local EXT_START = -5

-- Includes entity files that are in a folder.
local function includeEntityFiles(path, clientOnly)
    -- Include the entity if it includes a init.lua and cl_init.lua
    if (SERVER and file.Exists(path.."/init.lua", "LUA") or CLIENT) then
        -- Include the serverside portion.
        nut.util.include(path.."/init.lua", clientOnly and "client" or "server")

        -- Include the clientside portion.
        if (file.Exists(path.."/cl_init.lua", "LUA")) then
            nut.util.include(path.."/cl_init.lua")

            return true
        end

        -- Effects only need an init.lua so end the including here.
        if (clientOnly) then
            return true
        end
    end

    -- If the folder only has a shared.lua, include it.
    if (file.Exists(path.."/shared.lua", "LUA")) then
        nut.util.include(path.."/shared.lua", "shared")
        
        return true
    end

    return false
end

-- Includes all entities within a given folder.
local function includeEntities(path, folder, variable, registerFunc,
defaultInfo, clientOnly)
    defaultInfo = defaultInfo or {}

    -- Find all the entities.
    local files, folders = file.Find(path.."/"..folder.."/*", "LUA")
    
    -- Include all the folder entities.
    for _, entity in ipairs(folders) do
        local entityPath = path.."/"..folder.."/"..entity

        -- Include the entity file.
        _G[variable] = table.Copy(defaultInfo)
            _G[variable].ClassName = entity

            -- Register the entity after including it.
            if (includeEntityFiles(entityPath, clientOnly) and
                (clientOnly and CLIENT or not clientOnly)) then
                registerFunc(_G[variable], entity)
            end
        _G[variable] = nil
    end

    -- Include all the single file entities.
    for _, entity in ipairs(files) do
        local className = string.StripExtension(entity)

        _G[variable] = table.Copy(defaultInfo)
            _G[variable].ClassName = className

            -- Include the entity.
            nut.util.include(path.."/"..folder.."/"..entity,
                             clientOnly and "client" or "shared")

            -- Register the entity.
            if (clientOnly and CLIENT or not clientOnly) then
                registerFunc(_G[variable], className)
            end
        _G[variable] = nil
    end
end

nut.plugin.addComponent("item", {
    onInclude = function(plugin, path)
    	nut.item.loadFromDir(path)
    end
})

nut.plugin.addComponent("team", {
    onInclude = function(plugin, path)
    	nut.team.loadFromDir(path)
    end
})

nut.plugin.addComponent("entity", {
    onInclude = function(plugin, path)
        path = path.."/entities"

        -- Include scripted entities.
        includeEntities(path, "entities", "ENT", scripted_ents.Register, {
            Type = "anim",
            Base = "base_gmodentity"
        })

        -- Include scripted weapons.
        includeEntities(path, "weapons", "SWEP", weapons.Register, {
            Primary = {},
            Secondary = {},
            Base = "weapon_base"
        })

        -- Include scripted effects.
        includeEntities(path, "effects", "EFFECT", effects and effects.Register,
                        nil, true)
    end
})

nut.plugin.addComponent("libraries", {
    onInclude = function(plugin, path)
        for _, library in ipairs(file.Find(path.."/libraries/*.lua", "LUA")) do
            nut.util.include(path.."/libraries/"..library)
        end
    end
})