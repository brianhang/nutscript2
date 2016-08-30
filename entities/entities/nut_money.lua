AddCSLuaFile()

-- Some basic information about the entity.
ENT.Type = "anim"
ENT.PrintName = "Money"
ENT.Spawnable = false

-- Set up the amount of money variable.
function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Amount")
end

if (SERVER) then
    -- The default size of the money entity in Source units.
    local SIZE = 8

    -- Called to set up the entity.
    function ENT:Initialize()
        -- Set the model.
        self:SetModel(nut.currency.model or "models/props_lab/box01a.mdl")
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)

        -- Set use type to act like a button.
        self:SetUseType(SIMPLE_USE)

        -- Set up the physics for the entity.
        local physObj = self:GetPhysicsObject()

        if (IsValid(physObj)) then
            -- Allow the money entity to freely move.
            physObj:EnableMotion(true)
            physObj:Wake()
        else
            -- Set up a default size if the model for the entity
            -- is not working.
            local min, max = Vector(-SIZE, -SIZE, -SIZE),
                             Vector(SIZE, SIZE, SIZE)

            self:PhysicsInitBox(min, max)
            self:SetCollisionBounds(min, max)
        end
    end

    -- Allow for money entities to combine.
    function ENT:StartTouch(other)
        if (other:GetClass() == self:GetClass()) then
            self:SetAmount(self:GetAmount() + other:GetAmount())
            other:Remove()
        end
    end

    -- Allow players to pick up the money.
    function ENT:Use(client)
        local character = client:getChar()

        if (character) then
            if (hook.Run("PlayerPickupMoney", client, self) == false) then
                return
            end

            character:giveMoney(self:GetAmount())
            self:Remove()
        end
    end
end
