-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)
local rarityColors = require(ReplicatedStorage.src.GameConfiguration.General.rarityColors)
local viewportHandler = require(ReplicatedStorage.src.utility.viewportHandler)

-- Constants
local ItemAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Items")

-->
local InventoryGui = {
	Cards = {},
}

-- Private Methods
function InventoryGui:syncCard(card, itemName)
	local isEquipped = table.find(self.DataController:GetValue("Equipped"), itemName)
	card:WaitForChild("Checkmark").Visible = isEquipped
end

function InventoryGui:newCard(itemName)
	local newCard = self.Template:Clone()
	newCard.Name = itemName

	local config = itemConfig[itemName]

	local rarityColor = rarityColors[config.Rarity]
	newCard:WaitForChild("Gradient").BackgroundColor3 = rarityColor
	newCard:WaitForChild("Rarity").Text = `{config.Rarity}`
	newCard:WaitForChild("Rarity").TextColor3 = rarityColor
	newCard:WaitForChild("ItemName").Text = itemName:gsub("%u", " %0"):gsub("^%s+", "")

	newCard:AddTag("GuiButton")
	newCard:SetAttribute("Type", "Action")
	newCard:SetAttribute("Action", "ToggleEquip")
	newCard:SetAttribute("ItemName", itemName)

	viewportHandler.Setup(newCard:WaitForChild("ViewportFrame"), ItemAssets:WaitForChild(itemName), {
		Padding = 1,
	})

	newCard.Visible = true
	newCard.Parent = self.Container
	self:syncCard(newCard, itemName)

	self.Cards[itemName] = newCard
end

function InventoryGui:preloadItems()
	for itemName: string, _ in pairs(self.DataController:GetValue("Inventory")) do
		self:newCard(itemName)
	end
end

-- LifeCycle
function InventoryGui:Init(player: Player)
	self.DataController = knit.GetController("DataController")
	self.Panel = player.PlayerGui:WaitForChild("Panels"):WaitForChild("Inventory")
	self.Container = self.Panel:WaitForChild("Body"):WaitForChild("ScrollingFrame")
	self.Template = self.Container:WaitForChild("Template")
	self.Template.Visible = false
	self:preloadItems()

	self.DataController:GetValueChangedSignal("Equipped"):Connect(function(newValue)
		for itemName, card in pairs(self.Cards) do
			self:syncCard(card, itemName)
		end
	end)

	self.DataController:GetValueChangedSignal("Inventory"):Connect(function(newValue)
		for itemName, _ in pairs(newValue) do
			if not self.Cards[itemName] then
				self:newCard(itemName)
			end
		end
	end)
end

return InventoryGui
