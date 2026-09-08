-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local viewportHandler = require(ReplicatedStorage.src.utility.viewportHandler)

-- Constants
local Items = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Items")

-->
local BackPack = {
	Cards = {},
}

-->
function BackPack:syncCard(index: number, card)
	local itemName = self.DataController:GetValue("Equipped")[index]
	card:WaitForChild("PlusVector").Visible = typeof(itemName) ~= "string"
	card:WaitForChild("Gradient").Visible = typeof(itemName) == "string"
	card:WaitForChild("ViewportFrame"):ClearAllChildren()
	if itemName then
		local asset = Items:WaitForChild(itemName)
		viewportHandler.Setup(card:WaitForChild("ViewportFrame"), asset, {
			Padding = 1,
			Offset = CFrame.new() * CFrame.Angles(0, math.rad(180), 0),
		})
	end
end

function BackPack:preloadCards()
	for i = 5, 1, -1 do
		local newCard = self.Template:Clone()
		newCard.Visible = true
		newCard.Name = `{i}`
		newCard.LayoutOrder = i

		newCard:AddTag("GuiButton")
		newCard:SetAttribute("Type", "PanelToggler")
		newCard:SetAttribute("PanelName", "Inventory")

		self:syncCard(i, newCard)
		newCard.Parent = self.Container

		self.Cards[i] = newCard
	end
end

-- LifeCycle
function BackPack:Init(player: Player)
	self.DataController = knit.GetController("DataController")

	self.Container = player.PlayerGui:WaitForChild("Hud"):WaitForChild("Container"):WaitForChild("BackPack")
	self.Template = self.Container:WaitForChild("Template")
	self.Template.Visible = false
	self:preloadCards()

	self.DataController:GetValueChangedSignal("Equipped"):Connect(function(_)
		for i, card in pairs(self.Cards) do
			self:syncCard(i, card)
		end
	end)
end

return BackPack
