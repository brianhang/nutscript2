--[[
File:    sh_sound.lua
Purpose: Creates a utility function for playing queued sounds.
--]]

local ADJUST_SOUND = SoundDuration("npc/metropolice/pain1.wav") > 0
                     and "" or "../../hl2/sound/"

    -- Emits sounds one after the other from an entity.
function nut.util.emitQueuedSounds(entity, sounds, delay, spacing,
volume, pitch)
    assert(type(sounds) == "table", "sounds is not a table")

    -- Let there be a delay before any sound is played.
    delay = delay or 0
    spacing = spacing or 0.1

    -- Loop through all of the sounds.
    for k, v in ipairs(sounds) do
        local postSet, preSet = 0, 0

        -- Determine if this sound has special time offsets.
        if (type(v) == "table") then
            postSet, preSet = tonumber(v[2]) or 0, tonumber(v[3]) or 0
            v = v[1]
        end

        -- Get the length of the sound.
        local length = SoundDuration(ADJUST_SOUND..v)

        -- If the sound has a pause before it is played, add it here.
        delay = delay + preSet

        -- Have the sound play in the future.
        timer.Simple(delay, function()
            -- Check if the entity still exists and play the sound.
            if (IsValid(entity)) then
                entity:EmitSound(tostring(v), volume, pitch)
            end
        end)

        -- Add the delay for the next sound.
        delay = delay + length + postSet + spacing
    end

    -- Return how long it took for the whole thing.
    return delay
end
