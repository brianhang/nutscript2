--[[
File:    cl_blur.lua
Purpose: Creates utility functions that are used to blur parts of the screen.
--]]

-- THe default blur intensity.
local BLUR_INTENSITY = 5

-- Create a configuration for the blurring method.
NUT_CVAR_CHEAPBLUR = CreateClientConVar("nut_chearblur", 0, true)

-- Create a variable to store the cheap blur state.
local useCheapBlur = NUT_CVAR_CHEAPBLUR:GetBool()

cvars.AddChangeCallback("nut_cheapblur", function(name, old, new)
    useCheapBlur = (tonumber(new) or 0) > 0
end)

-- Get the blurring material.
local blur = Material("pp/blurscreen")

-- Draws a blurred material over a panel.
function nut.util.drawBlur(panel, amount, passes)
    -- Intensity of the blur.
    amount = amount or BLUR_INTENSITY
    
    if (useCheapBlur) then
        surface.SetDrawColor(50, 50, 50, amount * 20)
        surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
    else
        surface.SetMaterial(blur)
        surface.SetDrawColor(255, 255, 255)

        local x, y = panel:LocalToScreen(0, 0)
        
        for i = -(passes or 0.2), 1, 0.2 do
            -- Do things to the blur material to make it blurry.
            blur:SetFloat("$blur", i * amount)
            blur:Recompute()

            -- Draw the blur material over the screen.
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
        end
    end
end

-- Draws a blurred material over a certain area of the screen.
function nut.util.drawBlurAt(x, y, w, h, amount, passes)
    -- Intensity of the blur.
    amount = amount or BLUR_INTENSITY

    if (useCheapBlur) then
        surface.SetDrawColor(50, 50, 50, amount * 20)
        surface.DrawRect(x, y, w, h)
    else
        surface.SetMaterial(blur)
        surface.SetDrawColor(255, 255, 255)

        local scrW, scrH = ScrW(), ScrH()
        local x2, y2 = x / scrW, y / scrH
        local w2, h2 = (x + w) / scrW, (y + h) / scrH

        for i = -(passes or 0.2), 1, 0.2 do
            blur:SetFloat("$blur", i * amount)
            blur:Recompute()

            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRectUV(x, y, w, h, x2, y2, w2, h2)
        end
    end
end
