-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local InventoryController = knit.CreateController({
	Name = "InventoryController",
})

-- Private Methods
function InventoryController:toggleResponse(response: { Status: boolean, Reason: string })
	if not response.Status then
		self.NotificationController:Push({
			Message = response.Reason,
			Color = Color3.fromRGB(255, 0, 0),
			Sound = "Decline",
		})
		return
	end
end

-- Public Methods
function InventoryController:ToggleEquip(itemName: string)
	local isEquipped = table.find(self.DataController:GetValue("Equipped"), itemName)
	if isEquipped then
		self.InventoryService
			:Unequip(itemName)
			:andThen(function(response: { Status: boolean, Reason: string })
				self:toggleResponse(response)
			end)
			:catch(warn)
	else
		self.InventoryService
			:Equip(itemName)
			:andThen(function(response: { Status: boolean, Reason: string })
				self:toggleResponse(response)
			end)
			:catch(warn)
	end
end

-- LifeCycle
function InventoryController:KnitInit()
	self.DataController = knit.GetController("DataController")
	self.NotificationController = knit.GetController("NotificationController")
	self.InventoryService = knit.GetService("InventoryService")
end

return InventoryController
