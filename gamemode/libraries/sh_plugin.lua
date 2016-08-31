--[[
File:    sh_plugin.lua
Purpose: Creates the plugin library which allows easier modification to
         the framework and gamemodes with drag and drop plugins.
--]]

-- Cache the plugin hooks.
HOOK_CACHE = {}

-- Where the file extension starts in a path.
local EXT_START = -4

nut.plugin = nut.plugin or {}
nut.plugins = nut.plugins or {}

-- A list of plugins that have been disabled.
nut.plugin.disabled = nut.plugin.disabled or {}

-- A list of things that are loaded with plugins.
nut.plugin.components = nut.plugin.components or {}

-- Adds a plugin component which allows for extra features to be loaded in.
function nut.plugin.addComponent(name, info)
    assert(type(name) == "string", "name is not a string")
    assert(type(info) == "table", "info is not a table")

    nut.plugin.components[name] = info
end

-- Includes plugins within a given directory.
local function includePluginDir(base)
    local files, folders = file.Find(base.."/plugins/*", "LUA")

    for _, path in ipairs(files) do
        nut.plugin.load(path:sub(1, EXT_START - 1), base.."/plugins/"..path)
    end

    for _, path in ipairs(folders) do
        nut.plugin.load(path, base.."/plugins/"..path)
    end
end

-- Loads all available plugins.
function nut.plugin.initialize()
    includePluginDir("nutscript2")
    includePluginDir(engine.ActiveGamemode())
    includePluginDir("ns_plugins")

    -- Load components for the gamemode.
    nut.plugin.loadComponents(GAMEMODE, engine.ActiveGamemode().."/gamemode")

    for name, component in pairs(nut.plugin.components) do
        if (type(component.onLoaded) == "function") then
            component.onLoaded(GAMEMODE)
        end
    end

    hook.Run("PluginInitialized")
end

-- Loads a plugin from a given path.
function nut.plugin.load(id, path, name)
    name = name or "plugin"

    assert(type(id) == "string", "id is not a string")
    assert(type(path) == "string", "path is not a string")
    assert(type(name) == "string", "name is not a string")

    if (hook.Run("PluginShouldLoad", id) == false) then
        return false
    end

    -- Create a table to store plugin information.
    local plugin = nut.plugins[id] or {id = id, path = path}
    local usingFile

    -- Make this table globally accessible.
    _G[name:upper()] = plugin

    -- Check if we are including a single file or a folder.
    if (path:sub(EXT_START) == ".lua") then
        nut.util.include(path, "shared")
        usingFile = true
    else
        assert(file.Exists(path.."/sh_"..name..".lua", "LUA"),
               id.." is missing sh_plugin.lua!")

        nut.util.include(path.."/sh_"..name..".lua")
        nut.plugin.loadComponents(plugin)
    end

    -- Register the plugin so it works.
    nut.plugin.register(plugin)
    hook.Run("PluginLoaded", plugin)

    -- Call the component's onLoaded.
    if (not usingFile) then
        for name, component in pairs(nut.plugin.components) do
            if (type(component.onLoaded) == "function") then
                component.onLoaded(plugin)
            end
        end
    end

    _G[name:upper()] = nil

    return true
end

-- Loads components of a plugin from a given path.
function nut.plugin.loadComponents(plugin, path)
    assert(type(plugin) == "table", "plugin is not a table")

    -- Include any plugin components.
    for name, component in pairs(nut.plugin.components) do
        if (type(component.onInclude) == "function" and
            hook.Run("PluginComponentShouldLoad", plugin, name) ~= false) then
            component.onInclude(plugin, path or plugin.path)
        end
    end

    hook.Run("PluginLoadComponents", plugin)
end

-- Sets up a plugin so it can be used by the framework.
function nut.plugin.register(plugin)
    assert(type(plugin) == "table", "plugin is not a table")
    assert(plugin.id, "plugin does not have an identifier")

    -- Notify the plugin that it is being registered.
    if (type(plugin.onRegister) == "function") then
        plugin:onRegister()
    end

    -- Add the plugin hooks to the list of plugin hooks.
    for name, callback in pairs(plugin) do
        if (type(callback) == "function") then
            HOOK_CACHE[name] = HOOK_CACHE[name] or {}
            HOOK_CACHE[name][plugin] = callback
        end
    end

    hook.Run("PluginRegistered", plugin)

    -- Add the plugin to the list of plugins.
    nut.plugins[tostring(plugin.id)] = plugin
end

-- Allow plugins to load their own plugins.
nut.plugin.addComponent("plugins", {
    onInclude = function(plugin, path)
        includePluginDir(path)
    end
})

-- Overwrite hook.Call so plugin hooks run.
hook.NutCall = hook.NutCall or hook.Call

function hook.Call(name, gm, ...)
    local hooks = HOOK_CACHE[name]

    -- Run the plugin hooks from the cache.
    if (hooks) then
        -- Possible return values, assuming there are no more than
        -- six return values.
        local a, b, c, d, e, f

        -- Run all the plugin hooks.
        for plugin, callback in pairs(hooks) do
            a, b, c, d, e, f = callback(plugin, ...)

            -- If a hook returned value(s), return it.
            if (a ~= nil) then
                return a, b, c, d, e, f
            end
        end
    end

    -- Otherwise, do the normal hook calls.
    return hook.NutCall(name, gm, ...)
end

nut.util.include("nutscript2/gamemode/core/sh_components.lua")