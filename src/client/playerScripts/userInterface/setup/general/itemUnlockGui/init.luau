-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local Spring = require(ReplicatedStorage.src.utility.Spring)

-- Constants
local Player = Players.LocalPlayer
local ItemUnlockScreenGui = Player.PlayerGui:WaitForChild("ItemUnlock")
local CanvasGroup = ItemUnlockScreenGui:WaitForChild("CanvasGroup")
local ViewportFrame = CanvasGroup:WaitForChild("ViewportFrame")
local CrateRngScreenGui = Player.PlayerGui:WaitForChild("CrateRng")

-->
local ItemUnlockGui = {
	Connections = {},
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

function ItemUnlockGui:animateNewItems(newItems: { string })
	ItemUnlockScreenGui.Enabled = true
	CrateRngScreenGui.Enabled = false
	ViewportFrame.Position = UDim2.fromScale(0.5, -1)
	Spring.target(ViewportFrame, 0.5, 8, {
		Position = UDim2.fromScale(0.5, 0.5),
	})

	self:clearConnections()
	Spring.completed(ViewportFrame, function()
		table.insert(
			self.Connections,
			Player:GetMouse().Button1Up:Once(function()
				ItemUnlockScreenGui.Enabled = false
				self:clearConnections()
			end)
		)
	end)
end

-- LifeCycle
function ItemUnlockGui:Init()
	self.CrateController = knit.GetController("CrateController")
	self.CrateController.Signals.AnimateNewItems:Connect(function(newItems: { string })
		self:clearConnections()
		self:animateNewItems(newItems)
	end)
end

return ItemUnlockGui
