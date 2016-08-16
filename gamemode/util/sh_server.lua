--[[
File:    sh_server.lua
Purpose: Provides some utility functions that relate to the server.
--]]

-- Bit mask for the IP address bytes.
local IP_BYTE_1 = 0xFF000000
local IP_BYTE_2 = 0x00FF0000
local IP_BYTE_3 = 0x0000FF00
local IP_BYTE_4 = 0x000000FF

-- How many bits to shift a byte within an IP.
local IP_SHIFT_1 = 8 * 3
local IP_SHIFT_2 = 8 * 2
local IP_SHIFT_3 = 8 * 1

-- Returns the IP address of the server, including the port, in decimal.
function nut.util.getAddress()
    local address = tonumber(GetConVarString("hostip"))

    if (not address) then
        return "127.0.0.1:"..GetConVarString("hostport")
    end

    return bit.rshift(bit.band(address, IP_BYTE_1), IP_SHIFT_1).."."..
           bit.rshift(bit.band(address, IP_BYTE_2), IP_SHIFT_2).."."..
           bit.rshift(bit.band(address, IP_BYTE_3), IP_SHIFT_3).."."..
           bit.band(address, IP_BYTE_4)..":"..
           GetConVarString("hostport")
end
