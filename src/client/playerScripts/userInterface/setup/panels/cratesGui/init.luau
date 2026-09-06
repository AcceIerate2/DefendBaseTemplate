-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Config Modules
local cratesConfig = require(ReplicatedStorage.src.GameConfiguration.General.cratesConfig)

-->
local CratesGui = {}

-- Private Methods
function CratesGui:preloadCards()
	for name, config: { Icon: string, Cost: number, CurrencyType: string, Items: { string: number } } in
		pairs(cratesConfig)
	do
	end
end

-- LifeCycle
function CratesGui:Init(player: Player)
	self.Panel = player.PlayerGui:WaitForChild("Panels"):WaitForChild("Crates")
	self.Container = self.Panel:WaitForChild("Body"):WaitForChild("ScrollingFrame")
	self.Template = self.Container:WaitForChild("Template")
	self:preloadCards()
end

return CratesGui
