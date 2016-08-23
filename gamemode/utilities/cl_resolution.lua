--[[
File:    cl_resolution.lua
Purpose: Sets up a hook that is triggered when the screen resolution changes.
--]]

-- How often a screen size check should be done.
local CHECK_INTERVAL = 1

local LAST_WIDTH = ScrW()
local LAST_HEIGHT = ScrH()

timer.Create("nutResolutionMonitor", CHECK_INTERVAL, 0, function()
    -- Get the current screen width.
    local scrW, scrH = ScrW(), ScrH()

    -- Check if anything is different.
    if (scrW ~= LAST_WIDTH or scrH ~= LAST_HEIGHT) then
        hook.Run("ScreenResolutionChanged", LAST_WIDTH, LAST_HEIGHT)

        LAST_WIDTH = scrW
        LAST_HEIGHT = scrH
    end
end)
