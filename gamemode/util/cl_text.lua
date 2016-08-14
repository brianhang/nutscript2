--[[
File:    cl_text.lua
Purpose: Creates utility functions for drawing text on the screen.
--]]

-- How transparent a text's shadow should be compared to the text color.
local SHADOW_ALPHA_RATIO = 0.575

-- Indices for text position.
local POSITION_X = 1
local POSITION_Y = 2

-- Create a generic font to use in case one is not given.
surface.CreateFont("nutGenericFont", {
    font = "Arial",
    size = 12,
    weight = 500
})

-- Create a table to store text data.
local TEXT_DATA = {pos = {0, 0}}

-- Draw a text with a shadow.
function nut.util.drawText(text, x, y, color, alignX, alignY, font, alpha)
    -- Set the default color to white.
    color = color or color_white

    -- Set up the text.
    TEXT_DATA.text = text
    TEXT_DATA.font = font or "nutGenericFont"
    TEXT_DATA.pos[POSITION_X] = x
    TEXT_DATA.pos[POSITION_Y] = y
    TEXT_DATA.color = color
    TEXT_DATA.xalign = alignX or 0
    TEXT_DATA.yalign = alignY or 0

    -- Draw the text.
    return draw.TextShadow(TEXT_DATA, 1,
                           alpha or (color.a * SHADOW_ALPHA_RATIO))
end

-- Wraps text so it does not pass a certain width.
function nut.util.wrapText(text, width, font)
    -- Set the surface font so size data works.
    font = font or "nutGenericFont"
    surface.SetFont(font)

    -- Get information about the given text.
    local exploded = string.Explode("%s", text, true)
    local line = ""
    local lines = {}
    local w = surface.GetTextSize(text)
    local maxW = 0
    
    -- Don't wrap if it is not needed.
    if (w <= width) then
        return {(text:gsub("%s", " "))}, w
    end
    
    -- Otherwise, break up the text into words and wrap when a certain word
    -- makes a line too long.
    for i = 1, #exploded do
        local word = exploded[i]
        line = line.." "..word
        w = surface.GetTextSize(line)
        
        if (w > width) then
            lines[#lines + 1] = line
            line = ""
            
            if (w > maxW) then
                maxW = w
            end
        end
    end

    if (line ~= "") then
        lines[#lines + 1] = line
    end
    
    return lines, maxW
end
