-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local HudController = knit.CreateController({
	Name = "HudController",
	Signals = {
		ToggleVisibility = Signal.new(),
	},
})

-- Public Methods
function HudController:ToggleVisibility(toggle: boolean)
	self.Signals.ToggleVisibility:Fire(toggle)
end

-- LifeCycle
function HudController:KnitInit() end

return HudController
