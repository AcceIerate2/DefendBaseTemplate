-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local PlayTween = require(ReplicatedStorage.src.utility.PlayTween)
local viewportHandler = require(ReplicatedStorage.src.utility.viewportHandler)

-- Config Modules
local cratesConfig = require(ReplicatedStorage.src.GameConfiguration.General.cratesConfig)
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)
local rarityColors = require(ReplicatedStorage.src.GameConfiguration.General.rarityColors)

-- References
local ItemAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Items")
local Player = Players.LocalPlayer
local CanvasGroup = Player.PlayerGui:WaitForChild("CrateRng"):WaitForChild("CanvasGroup")
local RngTemplate = CanvasGroup:WaitForChild("Template")

-- Constants
local MINIMUM_WIN_INDEX = 16
local MAXIMUM_WIN_INDEX = 20
local CARDS_AFTER_WINNER = 7
local SPIN_DURATION = 3.25

-->
local CrateRngGui = {
	Connections = {},
	Random = Random.new(),
}

-- Private Methods
function CrateRngGui:clear()
	CanvasGroup.Visible = false
	CanvasGroup.GroupTransparency = 1

	for _, connection in pairs(self.Connections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	table.clear(self.Connections)

	-- Keep the source template and CanvasGroup's UIListLayout.
	for _, child in CanvasGroup:GetChildren() do
		if child ~= RngTemplate and child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function CrateRngGui:getStrip(row)
	local content = row:WaitForChild("Content")
	content.ClipsDescendants = true

	-- Your existing Content currently holds UIListLayout + Template.
	-- This creates an inner frame that can move without moving the mask.
	local strip = content:FindFirstChild("Items")

	if not strip then
		strip = Instance.new("Frame")
		strip.Name = "Items"
		strip.BackgroundTransparency = 1
		strip.BorderSizePixel = 0
		strip.Size = UDim2.fromScale(1, 1)
		strip.Position = UDim2.fromOffset(0, 0)
		strip.Parent = content

		local layout = content:FindFirstChildWhichIsA("UIListLayout")
		local itemTemplate = content:FindFirstChild("Template")

		assert(layout, "Content needs a UIListLayout")
		assert(itemTemplate, "Content needs an item Template")

		layout.Parent = strip
		itemTemplate.Parent = strip
	end

	local layout = strip:FindFirstChildWhichIsA("UIListLayout")
	local itemTemplate = strip:FindFirstChild("Template")

	assert(layout, "Items needs a UIListLayout")
	assert(itemTemplate, "Items needs an item Template")

	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	itemTemplate.Visible = false

	return strip, itemTemplate
end

function CrateRngGui:getWeightedVisualItem(crateName: string): string
	local crateConfig = cratesConfig[crateName]
	assert(crateConfig, `Missing crate config for "{crateName}"`)

	local totalWeight = 0

	for _, weight in pairs(crateConfig.Items) do
		totalWeight += weight
	end

	local roll = self.Random:NextNumber(0, totalWeight)

	for itemName, weight in pairs(crateConfig.Items) do
		roll -= weight

		if roll <= 0 then
			return itemName
		end
	end

	for itemName in pairs(crateConfig.Items) do
		return itemName
	end

	error(`Crate "{crateName}" has no items`)
end

function CrateRngGui:setupItemCard(itemCard, itemName: string)
	local itemData = itemConfig[itemName]
	local itemAsset = ItemAssets:FindFirstChild(itemName)

	if not itemData or not itemAsset then
		warn(`Missing config or asset for crate item "{itemName}"`)
		return
	end

	local rarity = itemData.Rarity
	local rarityColor = rarityColors[rarity] or Color3.new(1, 1, 1)

	itemCard.Name = itemName
	itemCard:WaitForChild("ItemName").Text = itemName:gsub("%u", " %0"):gsub("^%s+", "")

	itemCard:WaitForChild("Gradient").BackgroundColor3 = rarityColor

	viewportHandler.Setup(itemCard:WaitForChild("ViewportFrame"), itemAsset, {
		Padding = 2,
	})
end

function CrateRngGui:loadItems(row, crateName: string, actualReward: string)
	local strip, itemTemplate = self:getStrip(row)

	for _, child in strip:GetChildren() do
		if child:IsA("GuiObject") and child ~= itemTemplate then
			child:Destroy()
		end
	end

	strip.Position = UDim2.fromOffset(0, 0)

	local winnerIndex = self.Random:NextInteger(MINIMUM_WIN_INDEX, MAXIMUM_WIN_INDEX)
	local totalCards = winnerIndex + CARDS_AFTER_WINNER
	local winnerCard

	for index = 1, totalCards do
		local itemName = actualReward

		if index ~= winnerIndex then
			itemName = self:getWeightedVisualItem(crateName)
		end

		local newItemCard = itemTemplate:Clone()
		newItemCard.Name = itemName
		newItemCard.LayoutOrder = index
		newItemCard.Visible = true
		newItemCard.Parent = strip

		self:setupItemCard(newItemCard, itemName)

		if index == winnerIndex then
			winnerCard = newItemCard
		end
	end

	return winnerCard
end

function CrateRngGui:animate(row, winnerCard)
	local content = row:WaitForChild("Content")
	local strip = content:WaitForChild("Items")
	local center = row:WaitForChild("Center")

	center.ZIndex = 10

	-- Both are screen-space positions, so their difference is the X offset
	-- needed to place the winner under the fixed yellow line.
	local centerX = center.AbsolutePosition.X + (center.AbsoluteSize.X / 2)
	local winnerX = winnerCard.AbsolutePosition.X + (winnerCard.AbsoluteSize.X / 2)
	local targetX = centerX - winnerX

	PlayTween(strip, TweenInfo.new(SPIN_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(targetX, 0),
	})
end

function CrateRngGui:getResults(rewards: any, amount: number?)
	if typeof(rewards) == "table" then
		return rewards
	end

	local results = table.create(amount or 1)

	for index = 1, amount or 1 do
		results[index] = rewards
	end

	return results
end

function CrateRngGui:setup(crateName: string, rewards: any, amount: number?)
	local results = self:getResults(rewards, amount)
	local spins = {}

	CanvasGroup.GroupTransparency = 1
	CanvasGroup.Visible = true

	for index, rewardName in ipairs(results) do
		local newRow = RngTemplate:Clone()
		newRow.Name = `Spin_{index}`
		newRow.LayoutOrder = index
		newRow.GroupTransparency = 1
		newRow.Visible = true
		newRow.Parent = CanvasGroup

		local winnerCard = self:loadItems(newRow, crateName, rewardName)

		table.insert(spins, {
			Row = newRow,
			WinnerCard = winnerCard,
		})
	end

	-- Lets the UIListLayouts calculate AbsolutePosition before we line up winners.
	RunService.Heartbeat:Wait()

	PlayTween(CanvasGroup, TweenInfo.new(0.15), {
		GroupTransparency = 0,
	})

	for _, spin in ipairs(spins) do
		PlayTween(spin.Row, TweenInfo.new(0.15), {
			GroupTransparency = 0,
		})

		self:animate(spin.Row, spin.WinnerCard)
	end
end

-- LifeCycle
function CrateRngGui:Init()
	RngTemplate.Visible = false
	CanvasGroup.GroupTransparency = 1
	CanvasGroup.Visible = false

	self.CrateController = knit.GetController("CrateController")

	self.CrateController.Signals.Animate:Connect(function(crateName: string, rewards: any, amount: number?)
		self:clear()
		self:setup(crateName, rewards, amount)
	end)
end

return CrateRngGui
