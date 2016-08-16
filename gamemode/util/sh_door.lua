--[[
Name:    sh_door.lua
Purpose: Creates utility functions that relates to doors.
--]]

local ENTITY = FindMetaTable("Entity")

-- The default time to respawn a door in seconds.
local DOOR_RESPAWN = 120

-- How much force to push the door's ragdoll by.
local DOOR_FORCE = 100

-- Returns whether or not an entity is a door.
function ENTITY:isDoor()
    return self:GetClass():find("door")
end

-- Returns which door is connected to this door.
function ENTITY:getDoorPartner()
    return self.nutPartner
end

if (SERVER) then
    -- Blasts a door down.
    function ENTITY:blastDoor(velocity, lifeTime, ignorePartner)
        -- Ignore blasting a door if this is not even a door.
        if (not self:isDoor()) then
            return
        end

        -- Remove the dummy if it already exists.
        if (IsValid(self.nutDummy)) then
            self.nutDummy:Remove()
        end

        velocity = velocity or VectorRand()*DOOR_FORCE
        lifeTime = lifeTime or DOOR_RESPAWN

        -- Blast the partner door too if applicable.
        local partner = self:getDoorPartner()

        if (IsValid(partner) and not ignorePartner) then
            partner:blastDoor(velocity, lifeTime, true)
        end

        -- Create a dummy door that resembles this door.
        local color = self:GetColor()

        local dummy = ents.Create("prop_physics")
        dummy:SetModel(self:GetModel())
        dummy:SetPos(self:GetPos())
        dummy:SetAngles(self:GetAngles())
        dummy:Spawn()
        dummy:SetColor(color)
        dummy:SetMaterial(self:GetMaterial())
        dummy:SetSkin(self:GetSkin() or 0)
        dummy:SetRenderMode(RENDERMODE_TRANSALPHA)
        dummy:CallOnRemove("restoreDoor", function()
            if (IsValid(self)) then
                self:SetNotSolid(false)
                self:SetNoDraw(false)
                self:DrawShadow(true)
                self.nutIgnoreUse = false
                self.nutIsMuted = false

                for k, v in ipairs(ents.FindByClass("prop_door_rotating")) do
                    if (v:GetParent() == self) then
                        v:SetNotSolid(false)
                        v:SetNoDraw(false)

                        if (v.onDoorRestored) then
                            v:onDoorRestored(self)
                        end
                    end
                end
            end
        end)
        dummy:SetOwner(self)
        dummy:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        for k, v in ipairs(self:GetBodyGroups()) do
            dummy:SetBodygroup(v.id, self:GetBodygroup(v.id))
        end

        -- Push the door in the given direction.
        dummy:GetPhysicsObject():SetVelocity(velocity)

        -- Make this door uninteractable.
        self:Fire("unlock")
        self:Fire("open")
        self:SetNotSolid(true)
        self:SetNoDraw(true)
        self:DrawShadow(false)
        self.nutDummy = dummy
        self.nutIsMuted = true
        self.nutIgnoreUse = true
        self:DeleteOnRemove(dummy)

        -- Notify other doors that this has been blasted.
        for k, v in ipairs(ents.FindByClass("prop_door_rotating")) do
            if (v:GetParent() == self) then
                v:SetNotSolid(true)
                v:SetNoDraw(true)

                if (v.onDoorBlasted) then
                    v:onDoorBlasted(self)
                end
            end
        end

        -- Bring back the old door after the given time has passed.
        local uniqueID = "doorRestore"..self:EntIndex()
        local uniqueID2 = "doorOpener"..self:EntIndex()

        timer.Create(uniqueID2, 1, 0, function()
            if (IsValid(self) and IsValid(self.nutDummy)) then
                self:Fire("open")
            else
                timer.Remove(uniqueID2)
            end
        end)

        timer.Create(uniqueID, lifeTime, 1, function()
            if (IsValid(self) and IsValid(dummy)) then
                uniqueID = "dummyFade"..dummy:EntIndex()
                local alpha = 255

                timer.Create(uniqueID, 0.1, 255, function()
                    if (IsValid(dummy)) then
                        alpha = alpha - 1
                        dummy:SetColor(ColorAlpha(color, alpha))

                        if (alpha <= 0) then
                            dummy:Remove()
                        end
                    else
                        timer.Remove(uniqueID)
                    end
                end)
            end
        end)

        return dummy
    end
end

-- Find all of the door partners.
hook.Add("InitPostEntity", "nutDoorPartnerFinder", function()
    local doors = ents.FindByClass("prop_door_rotating")

    -- Match every door with its partner.
    for _, door in ipairs(doors) do
        local door2 = door:GetOwner()

        if (IsValid(parent) and parent:isDoor()) then
            door.nutPartner = door2
            door2.nutPartner = door
        else
            for _, door2 in ipairs(doors) do
                if (door2:GetOwner() == door) then
                    door.nutPartner = door2
                    door2.nutPartner = door

                    break
                end
            end
        end
    end
end)
