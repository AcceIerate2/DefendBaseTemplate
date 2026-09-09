-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local Spring = require(ReplicatedStorage.src.utility.Spring)
local viewportHandler = require(ReplicatedStorage.src.utility.viewportHandler)

-- Config Modules
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)
local rarityColors = require(ReplicatedStorage.src.GameConfiguration.General.rarityColors)

-- Constants
local Player = Players.LocalPlayer
local ItemUnlockScreenGui = Player.PlayerGui:WaitForChild("ItemUnlock")
local CanvasGroup = ItemUnlockScreenGui:WaitForChild("CanvasGroup")
local ViewportFrames = CanvasGroup:WaitForChild("ViewportFrames")
local Template = ViewportFrames:WaitForChild("Template")
local CrateRngScreenGui = Player.PlayerGui:WaitForChild("CrateRng")
local ItemAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Items")

-->
local ItemUnlockGui = {
	Connections = {},
	ItemFrames = {},
}

-- Private Methods
function ItemUnlockGui:clearConnections()
	for _, connection: RBXScriptConnection in pairs(self.Connections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	table.clear(self.Connections)
end

function ItemUnlockGui:animateNewItems(newItems: { string }, callback)
	ItemUnlockScreenGui.Enabled = true
	CrateRngScreenGui.Enabled = false

	Template.Visible = false
	for _, itemFrame in pairs(self.ItemFrames) do
		itemFrame:Destroy()
	end

	for _, itemName: string in pairs(newItems) do
		local rarity = itemConfig[itemName].Rarity
		local rarityColor = rarityColors[rarity]

		local newFrame = Template:Clone()
		newFrame:WaitForChild("Gradient").BackgroundColor3 = rarityColor
		newFrame:WaitForChild("Rarity").Text = rarity
		newFrame:WaitForChild("Rarity").TextColor3 = rarityColor
		newFrame:WaitForChild("ItemName").Text = itemName:gsub("%u", " %0"):gsub("^%s+", "")

		local itemAsset = ItemAssets:WaitForChild(itemName)
		viewportHandler.Setup(newFrame:WaitForChild("ViewportFrame"), itemAsset, {
			Padding = 2,
		})

		newFrame.Visible = true
		newFrame.Name = itemName
		newFrame.Parent = ViewportFrames
		table.insert(self.ItemFrames, newFrame)
	end

	ViewportFrames.Position = UDim2.fromScale(0.5, -1)
	Spring.target(ViewportFrames, 0.5, 8, {
		Position = UDim2.fromScale(0.5, 0.5),
	})

	self:clearConnections()
	Spring.completed(ViewportFrames, function()
		table.insert(
			self.Connections,
			Player:GetMouse().Button1Up:Once(function()
				ItemUnlockScreenGui.Enabled = false
				self:clearConnections()
				callback()
			end)
		)
	end)
end

-- LifeCycle
function ItemUnlockGui:Init()
	self.CrateController = knit.GetController("CrateController")
	self.CrateController.Signals.AnimateNewItems:Connect(function(newItems: { string }, callback)
		self:clearConnections()
		self:animateNewItems(newItems, callback)
	end)
end

return ItemUnlockGui
