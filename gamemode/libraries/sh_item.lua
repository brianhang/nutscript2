--[[
File:    libraries/sh_item.lua
Purpose: Sets up a system so items and inventories can be used to manage
         things which characters can interact with.
--]]

-- Where the file extension starts.
local EXTENSION = -5

nut.item = nut.item or {}
nut.item.list = nut.item.list or {}
nut.item.abstract = nut.item.abstract or {}

-- Loads an item from a given file.
function nut.item.load(path, parentItem, isAbstract)
    assert(type(path) == "string", "path is not a string")

    -- Create a string identifier for the item.
    local id = string.GetFileFromFilename(path)
    id = id:sub(1, EXTENSION)
    id = id:gsub("sh_", "")

    -- Set up a global table so the file can store item information.
    ITEM = {id = id}

    -- If a parent ID is given, derive the item from the parent.
    if (parentItem) then
        local parent = nut.item.abstract[parentItem] or
                       nut.item.list[parentItem]

        if (parent) then
            table.Inherit(ITEM, parent)
        else
            ErrorNohalt("Parent '"..parentItem.."' does not exist for"..
                        " item ("..path..")")
        end
    end

    -- Include and register the item.
    nut.util.include(path, "shared")
    nut.item.register(ITEM)

    ITEM = nil
end

-- Loads all the items within a given directory.
function nut.item.loadFromDir(path)
    assert(type(path) == "string", "path is not a string")

    -- Look in the items directory within path.
    path = path.."/items/"

    -- Load all the base items first as abstract items.
    local _, baseItems = file.Find(path.."base/*.lua", "LUA")

    for _, basePath in ipairs(baseItems) do
        nut.item.load(path.."base/"..basePath, nil, true)
    end

    -- Find all the items within the path.
    local files, folders = file.Find(path.."*", "LUA")

    -- Load all the files as regular items.
    for _, itemPath in ipairs(files) do
        nut.item.load(path..itemPath)
    end

    -- Load all the folders as items that derive from a parent.
    -- The folder's name should match the parent's identifier.
    for _, folderPath in ipairs(folders) do
        -- Ignore the base folder since we already checked it.
        if (folderPath == "base") then
            continue
        end

        local files = file.Find(path..folderPath.."/*.lua", "LUA")

        for _, itemPath in ipairs(files) do
            nut.item.load(path..folderPath.."/"..itemPath, folderPath)
        end
    end
end

-- Sets up an item so it can be used.
function nut.item.register(item)
    assert(type(item) == "table", "item is not a table")

    -- Store the item in its correct list.
    if (ITEM.isAbstract or isAbstract) then
        nut.item.abstract[ITEM.id] = ITEM
    else
        nut.item.list[ITEM.id] = ITEM
    end

    -- Notify the item that it was registered.
    if (type(ITEM.onRegistered) == "function") then
        ITEM:onRegistered()
    end

    -- Notify the parent that it was registered.
    if (ITEM.BaseClass and
        type(ITEM.BaseClass.onChildRegistered) == "function") then
        ITEM.BaseClass:onChildRegistered(item)
    end

    hook.Run("ItemRegistered", item)
end

-- Add some functions to the inventory class.
local INVENTORY = nut.meta.inventory

-- Adds an item to the inventory.
function INVENTORY:add()
    error("INVENTORY:add() has not been overwritten!")
end

-- Removes an item to the inventory.
function INVENTORY:remove()
    error("INVENTORY:remove() has not been overwritten!")
end
