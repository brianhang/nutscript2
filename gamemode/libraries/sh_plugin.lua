--[[
File:    sh_plugin.lua
Purpose: Creates the plugin library which allows easier modification to
         the framework and gamemodes with drag and drop plugins.
--]]

-- Where the file extension starts in a path.
local EXT_START = -4

nut.plugin = nut.plugin or {}
nut.plugins = {}

-- A list of plugins that have been disabled.
nut.plugin.disabled = nut.plugin.disabled or {}

-- A list of things that are loaded with plugins.
nut.plugin.components = {}

-- A list of code that will run on clients once they initialize.
nut.plugin.clientLua = {}

-- Adds a plugin component which allows for extra features to be loaded in.
function nut.plugin.addComponent(name, info)
    assert(type(name) == "string", "name is not a string")
    assert(type(info) == "table", "info is not a table")

    nut.plugin.components[name] = info
end

-- Loads all available plugins.
function nut.plugin.initialize()
    local function includePluginDir(base)
        local files, folders = file.Find(base.."/plugins/*", "LUA")

        for _, path in ipairs(files) do
            nut.plugin.load(path:sub(1, EXT_START - 1), base.."/plugins/"..path)
        end

        for _, path in ipairs(folders) do
            nut.plugin.load(path, base.."/plugins/"..path)
        end
    end

    includePluginDir("nutscript2")
    includePluginDir(engine.ActiveGamemode())

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
    local plugin = {id = id, path = path}
    local usingFile

    -- Make this table globally accessible.
    _G[name:upper()] = plugin

    -- Check if we are including a single file or a folder.
    if (path:sub(EXT_START) == ".lua") then
        nut.util.include(path)
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

    return true
end

-- Loads components of a plugin from a given path.
function nut.plugin.loadComponents(plugin)
    assert(type(plugin) == "table", "plugin is not a table")

    -- Include any plugin components.
    for name, component in pairs(nut.plugin.components) do
        if (type(component.onInclude) == "function" and
            hook.Run("PluginComponentShouldLoad", plugin, name) ~= false) then
            component.onInclude(plugin, path)
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

    hook.Run("PluginRegistered", plugin)

    -- Add the plugin to the list of plugins.
    nut.plugins[tostring(plugin.id)] = plugin
end
