-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local viewportHandler = require(ReplicatedStorage.src.utility.viewportHandler)

-- Config Modules
local cratesConfig = require(ReplicatedStorage.src.GameConfiguration.General.cratesConfig)
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)
local rarityColors = require(ReplicatedStorage.src.GameConfiguration.General.rarityColors)

-- Constants
local ItemAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Items")

-->
local CratesGui = {}

-- Private Methods
function CratesGui:preloadCards()
	for name, config: { Icon: string, Cost: number, CurrencyType: string, Items: { string: number } } in
		pairs(cratesConfig)
	do
		local newCard = self.Template:Clone()
		newCard.Name = name

		newCard.LayoutOrder = config.Cost
		newCard:WaitForChild("Labels"):WaitForChild("Cost"):WaitForChild("Label").Text = `${NumberShortner(config.Cost)}`
		newCard:WaitForChild("Labels"):WaitForChild("ViewButton"):WaitForChild("Button"):SetAttribute("CrateName", name)
		newCard:WaitForChild("Title").Text = name:gsub("%u", " %0"):gsub("^%s+", "")
		newCard:WaitForChild("ViewportFrame"):WaitForChild("ImageLabel").Image = config.Icon

		local totalWeight = 0
		for _, weight in pairs(config.Items) do
			totalWeight += weight
		end

		local itemTemplate = newCard:WaitForChild("Items"):WaitForChild("Template")
		itemTemplate.Visible = false

		for itemName: string, weight: number in pairs(config.Items) do
			local percent = math.round((weight/totalWeight) * 100)
			local rarity = itemConfig[itemName].Rarity	
			local rarityColor = rarityColors[rarity]

			local newItemCard = itemTemplate:Clone()
			newItemCard:WaitForChild("Percent").Text = `%{percent}`
			newItemCard:WaitForChild("Gradient").BackgroundColor3 = rarityColor
			
			local itemAsset = ItemAssets:WaitForChild(itemName)
			viewportHandler.Setup(newItemCard:WaitForChild("ViewportFrame"), itemAsset, {
				Padding = 1,
			})

			newItemCard.Name = itemName
			newItemCard.Visible = true
			newItemCard.Parent = newCard:WaitForChild("Items")
		end

		newCard.Visible = true
		newCard.Parent = self.Container
	end
end

-- LifeCycle
function CratesGui:Init(player: Player)
	self.Panel = player.PlayerGui:WaitForChild("Panels"):WaitForChild("Crates")
	self.Container = self.Panel:WaitForChild("Body"):WaitForChild("ScrollingFrame")
	self.Template = self.Container:WaitForChild("Template")
	self.Template.Visible = false
	self:preloadCards()
end

return CratesGui
