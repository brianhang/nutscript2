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
nut.item.inventories = nut.item.inventories or {}

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

-- Instances a new inventory object.
function nut.item.newInv(id, owner)
    -- Provide default values for the id and owner.
    if (type(id) ~= "number") then
        id = 0
    end

    if (type(owner) ~= "number") then
        owner = 0
    end

    -- Create a new inventory metatable.
    local inventory = setmetatable({id = id, owner = owner}, nut.meta.inventory)
    nut.item.inventories[id] = inventory

    -- Adjust the instance if needed.
    hook.Run("InventoryInstanced", inventory)

    return inventory
end

-- Serverside portion for inventories.
if (CLIENT) then return end

-- Creates a new inventory that is stored in the database.
function nut.item.createInv(owner, callback)
    assert(type(owner) == "number", "owner is not a number")

    -- Insert the inventory into the database.
    nut.db.insert(INVENTORIES, {ownerID = owner}, function(results)
        if (results) then
            -- Get the unique ID for the inventory.
            local id = nut.db.getInsertID()

            -- Create an inventory object.
            local inventory = nut.item.newInv(id, owner)
            hook.Run("InventoryCreated", inventory)

            -- Run the callback with the inventory.
            if (type(callback) == "function") then
                callback(inventory)
            end
        end
    end)
end

-- Loads an inventory from the database into an object.
function nut.item.restoreInv(id, callback)
    assert(type(id) == "number", "id is not a number")
    assert(id >= 0, "id can not be negative")

    -- Select the inventory corresponding to the given ID
    -- from the database.
    nut.db.select(INVENTORIES, {"ownerID"}, "invID = "..id, function(results)
        if (results and results[1]) then
            results = results[1]

            -- Create an inventory object using the results.
            local inventory = nut.item.newInv(id,
                                              tonumber(results.ownerID) or 0)
            hook.Run("InventoryRestored", inventory)

            -- Load the inventory's items.
            inventory:load(function()
                hook.Run("InventoryLoaded", inventory)

                -- Run the callback passing the inventory.
                if (type(callback) == "function") then
                    callback(inventory)
                end
            end)
        elseif (type(callback) == "function") then
            callback()
        end
    end)
end

-- Loads inventories which belongs to a given owner.
function nut.item.restoreInvFromOwner(owner, callback, limit)
    assert(type(owner) == "number", "owner must be a number")
    assert(owner >= 0, "owner can not be negative")

    -- Select the inventories that belong to the given owner.
    nut.db.select(INVENTORIES, {"invID"}, "ownerID = "..owner,
    function(results)
        if (results and #results > 0) then
            -- Convert each result into an inventory object.
            for index, result in ipairs(results) do
                -- Create an inventory object using the results.
                local inventory = nut.item.newInv(tonumber(result.invID) or 0,
                                                  owner)

                -- Store the inventory.
                nut.item.inventories[inventory.id] = inventory

                hook.Run("InventoryRestored", inventory, index)

                -- Load the inventory's items.
                inventory:load(function()
                    hook.Run("InventoryLoaded", inventory, index)

                    -- Run the callback with the loaded inventory.
                    if (type(callback) == "function") then
                        callback(inventory, index)
                    end
                end)
            end
        elseif (type(callback) == "function") then
            callback()
        end
    end, limit, "invID")
end

hook.Add("DatabaseConnected", "nutInventoryTable", function()
    local MYSQL_CREATE = [[
    CREATE TABLE IF NOT EXISTS `%s` (
        `invID` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `ownerID` INT(11) UNSIGNED NOT NULL
    ) AUTO_INCREMENT=1;
    ]]

    local SQLITE_CREATE = [[
    CREATE TABLE IF NOT EXISTS `%s` (
        `invID` INTEGER PRIMARY KEY NOT NULL,
        `ownerID` INTEGER NOT NULL
    );
    ]]

    -- The table name for the inventories.
    INVENTORIES = engine.ActiveGamemode():lower().."_inventories"

    -- Create the inventories table.
    if (nut.db.sqlModule == nut.db.modules.sqlite) then
        nut.db.query(SQLITE_CREATE:format(INVENTORIES))
    else
        nut.db.query(MYSQL_CREATE:format(INVENTORIES))
    end
end)