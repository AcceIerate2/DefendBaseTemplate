-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local InventoryService = knit.CreateService({
	Name = "InventoryService",
})

-- Client Exposed Methods
function InventoryService.Client:Unequip(player: Player, itemName: string)
	return self.Server:Unequip(player, itemName)
end

function InventoryService.Client:Equip(player: Player, itemName: string)
	return self.Server:Equip(player, itemName)
end

-- Private Methods
function InventoryService:getEquippedVO(player: Player)
	return self.DataService:GetValueObject(player, "Equipped")
end

function InventoryService:getInventoryVO(player: Player)
	return self.DataService:GetValueObject(player, "Inventory")
end

function InventoryService:canEquip(player: Player): boolean
	local maxSlots = self.DataService:GetValue(player, "Slot5") and 5 or 4
	return #self:getEquippedVO(player):Get() < maxSlots
end

function InventoryService:isEquipped(player: Player, itemName: string): boolean
	return table.find(self:getEquippedVO(player):Get(), itemName) ~= nil
end

function InventoryService:ownsItem(player: Player, itemName: string): boolean
	return self:getInventoryVO(player):Get()[itemName] ~= nil
end

-- Public Methods
function InventoryService:Equip(player: Player, itemName: string)
	-- Validation
	if not self:ownsItem(player, itemName) then
		return {
			Status = false,
			Reason = "You don't own this!",
		}
	end

	if self:isEquipped(player, itemName) then
		return {
			Status = false,
			Reason = `Already Equipped!`,
		}
	end

	if not self:canEquip(player) then
		return {
			Status = false,
			Reason = `Not Enough Slots!`,
		}
	end

	-- Equip & Update Data
	local availableSlot = (function()
		for i = 1, self.DataService:GetValue(player, "Slot5") and 5 or 4 do
			if self:getEquippedVO(player):Get()[i] == nil then
				return i
			end
		end
		return nil
	end)()

	if not availableSlot then
		return {
			Status = false,
			Reason = "Could not find an available Slot",
		}
	end

	self:getEquippedVO(player):Update(function(mutator)
		mutator[availableSlot] = itemName
	end)

	-- Return a Response to the Client
	return {
		Status = true,
	}
end

function InventoryService:Unequip(player: Player, itemName: string)
	if not self:isEquipped(player, itemName) then
		return {
			Status = false,
			Reason = "Already Not Equipped!",
		}
	end

	local indexToClear = table.find(self:getEquippedVO(player):Get(), itemName)
	if not indexToClear then
		return {
			Status = false,
			Reason = "Something went wrong, try again.",
		}
	end

	self:getEquippedVO(player):Update(function(mutator)
		table.remove(mutator, indexToClear)
	end)

	return {
		Status = true,
	}
end

function InventoryService:AddToInventory(player: Player, itemName: string)
	self:getInventoryVO(player, itemName):Update(function(mutator)
		mutator[itemName] = true
	end)
end

-- LifeCycle
function InventoryService:KnitInit()
	self.DataService = knit.GetService("DataService")
end

return InventoryService
