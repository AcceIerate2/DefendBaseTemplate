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
local POOL_BUFFER = 3
local SPIN_DURATION = 3.25

-->
local CrateRngGui = {
	Connections = {},
	Random = Random.new(),
}

-- Private Methods
function CrateRngGui:clear()
	CanvasGroup.Parent.Enabled = false
	CanvasGroup.Visible = false
	CanvasGroup.GroupTransparency = 1

	for _, connection in pairs(self.Connections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	table.clear(self.Connections)

	for _, child in CanvasGroup:GetChildren() do
		if child ~= RngTemplate and child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function CrateRngGui:getStrip(row)
	local content = row:WaitForChild("Content")
	content.ClipsDescendants = true

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

	return strip, itemTemplate, layout
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

	-- This must replace old viewport contents when called on a recycled card.
	viewportHandler.Setup(itemCard:WaitForChild("ViewportFrame"), itemAsset, {
		Padding = 2,
	})
end

function CrateRngGui:loadItems(row, crateName: string, actualReward: string)
	local strip, itemTemplate, layout = self:getStrip(row)
	local content = row:WaitForChild("Content")

	for _, child in strip:GetChildren() do
		if child:IsA("GuiObject") and child ~= itemTemplate then
			child:Destroy()
		end
	end

	strip.Position = UDim2.fromOffset(0, 0)

	local itemWidth = itemTemplate.AbsoluteSize.X
	local padding = layout.Padding.Offset + (layout.Padding.Scale * content.AbsoluteSize.X)
	local estimatedCellWidth = itemWidth + padding

	assert(estimatedCellWidth > 0, "Item Template has no visible width")

	-- Usually 8–10 physical cards instead of 23–27 per reel.
	local poolSize = math.max(2, math.ceil(content.AbsoluteSize.X / estimatedCellWidth) + POOL_BUFFER)

	local winnerIndex = self.Random:NextInteger(MINIMUM_WIN_INDEX, MAXIMUM_WIN_INDEX)
	local sequenceLength = winnerIndex + poolSize + 2
	local sequence = table.create(sequenceLength)

	for index = 1, sequenceLength do
		if index == winnerIndex then
			sequence[index] = actualReward
		else
			sequence[index] = self:getWeightedVisualItem(crateName)
		end
	end

	local pool = table.create(poolSize)

	for index = 1, poolSize do
		local newItemCard = itemTemplate:Clone()
		newItemCard.LayoutOrder = index
		newItemCard.Visible = true
		newItemCard.Parent = strip

		self:setupItemCard(newItemCard, sequence[index])
		pool[index] = newItemCard
	end

	-- This is a clone's template, not the original RngTemplate.
	-- The pool reuses its cards, so it is no longer needed.
	itemTemplate:Destroy()

	return {
		Row = row,
		Strip = strip,
		Center = row:WaitForChild("Center"),

		Pool = pool,
		Sequence = sequence,
		CrateName = crateName,

		WinnerIndex = winnerIndex,
		NextSequenceIndex = poolSize + 1,
		NextLayoutOrder = poolSize + 1,
		PassedSlots = 0,
	}
end

function CrateRngGui:prepareSpin(spin)
	local firstCard = spin.Pool[1]
	local secondCard = spin.Pool[2]

	local cellWidth = secondCard.AbsolutePosition.X - firstCard.AbsolutePosition.X
	assert(cellWidth > 0, "Could not calculate crate-card spacing")

	local firstCardCenter = firstCard.AbsolutePosition.X + (firstCard.AbsoluteSize.X / 2)
	local selectorCenter = spin.Center.AbsolutePosition.X + (spin.Center.AbsoluteSize.X / 2)

	spin.Center.ZIndex = 10
	spin.CellWidth = cellWidth
	spin.TargetDistance = math.max(0, firstCardCenter + ((spin.WinnerIndex - 1) * cellWidth) - selectorCenter)
end

function CrateRngGui:recycleCard(spin)
	local card = table.remove(spin.Pool, 1)

	local itemName = spin.Sequence[spin.NextSequenceIndex] or self:getWeightedVisualItem(spin.CrateName)

	spin.NextSequenceIndex += 1

	-- The offscreen left card becomes the new far-right card.
	card.LayoutOrder = spin.NextLayoutOrder
	spin.NextLayoutOrder += 1

	self:setupItemCard(card, itemName)
	table.insert(spin.Pool, card)
end

function CrateRngGui:animate(spins, onFinished)
	local startedAt = os.clock()
	local connection

	connection = RunService.RenderStepped:Connect(function()
		local alpha = math.min((os.clock() - startedAt) / SPIN_DURATION, 1)
		local easedAlpha = 1 - (1 - alpha) ^ 5

		for _, spin in ipairs(spins) do
			local distance = spin.TargetDistance * easedAlpha
			local passedSlots = math.floor(distance / spin.CellWidth)

			while spin.PassedSlots < passedSlots do
				spin.PassedSlots += 1
				self:recycleCard(spin)
			end

			local remainder = distance - (passedSlots * spin.CellWidth)
			spin.Strip.Position = UDim2.fromOffset(-remainder, 0)
		end

		if alpha >= 1 then
			connection:Disconnect()

			if onFinished then
				onFinished()
			end
		end
	end)

	table.insert(self.Connections, connection)
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

function CrateRngGui:setup(crateName: string, rewards: any, amount: number?, callback)
	local results = self:getResults(rewards, amount)
	local pendingRows = {}
	local spins = {}

	CanvasGroup.Parent.Enabled = true
	CanvasGroup.GroupTransparency = 1
	CanvasGroup.Visible = true

	-- Parent rows first so their real sizes can calculate.
	for index, rewardName in ipairs(results) do
		local newRow = RngTemplate:Clone()
		newRow.Name = `Spin_{index}`
		newRow.LayoutOrder = index
		newRow.GroupTransparency = 1
		newRow.Visible = true
		newRow.Parent = CanvasGroup

		table.insert(pendingRows, {
			Row = newRow,
			Reward = rewardName,
		})
	end

	RunService.Heartbeat:Wait()

	-- Create only each row's small reusable card pool.
	for _, pendingRow in ipairs(pendingRows) do
		table.insert(spins, self:loadItems(pendingRow.Row, crateName, pendingRow.Reward))
	end

	RunService.Heartbeat:Wait()

	for _, spin in ipairs(spins) do
		self:prepareSpin(spin)

		PlayTween(spin.Row, TweenInfo.new(0.15), {
			GroupTransparency = 0,
		})
	end

	PlayTween(CanvasGroup, TweenInfo.new(0.15), {
		GroupTransparency = 0,
	})

	if #spins == 0 then
		CanvasGroup.Parent.Enabled = false

		if callback then
			callback:Fire(results)
		end

		return
	end

	-- One RenderStepped connection updates every reel.
	self:animate(spins, function()
		CanvasGroup.Parent.Enabled = false

		if callback then
			callback:Fire(results)
		end
	end)
end

-- LifeCycle
function CrateRngGui:Init()
	RngTemplate.Visible = false
	CanvasGroup.GroupTransparency = 1
	CanvasGroup.Visible = false

	self.CrateController = knit.GetController("CrateController")

	self.CrateController.Signals.Animate:Connect(
		function(crateName: string, rewards: string | { string }, amount: number?, callback)
			self:clear()
			self:setup(crateName, rewards, amount, callback)
		end
	)
end

return CrateRngGui
