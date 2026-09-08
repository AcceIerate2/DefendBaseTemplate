-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local Hud = {}

-- LifeCycle
function Hud:Init(player: Player)
	self.HudFrame = player.PlayerGui:WaitForChild("Hud")

	self.HudController = knit.GetController("HudController")
	self.HudController.Signals.ToggleVisibility:Connect(function(toggle: boolean)
		local groupTransparency = toggle and 0 or 1
		local tween =
			TweenService:create(self.HudFrame:WaitForChild("Container"), TweenInfo.new(0.15, Enum.EasingStyle.Linear), {
				GroupTransparency = groupTransparency,
			}) :: Tween

		tween:Play()
		tween.Completed:Once(function()
			tween:Destroy()
		end)
	end)
end

return Hud
