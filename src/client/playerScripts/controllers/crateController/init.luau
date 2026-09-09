-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local CrateController = knit.CreateController({
	Name = "CrateController",
	Signals = {
		Animate = Signal.new(),
		AnimateNewItems = Signal.new(),
	},
})

-- Public Methods
function CrateController:OpenCrate(crateName: string, amount: number)
	self.CrateService
		:OpenCrate(crateName, amount)
		:andThen(
			function(response: { Status: boolean, Reason: string?, Items: { number: string }? }, NewItems: { string })
				if not response.Status and typeof(response.Reason) == "string" then
					self.NotificationController:Push({
						Message = response.Reason,
						Color = Color3.fromRGB(255, 0, 0),
						Sound = "Decline",
					})
					return
				end

				self.PanelController:togglePanel("CrateInfo")
				self.HudController:ToggleVisibility(false)

				local callback = Signal.new()
				callback:Once(function()
					callback:DisconnectAll()
					callback:Destroy()
					self.Signals.AnimateNewItems:Fire(NewItems)
				end)

				self.Signals.Animate:Fire(crateName, response.Items, amount, callback)
			end
		)
		:catch(warn)
end

-- LifeCycle
function CrateController:KnitInit()
	self.CrateService = knit.GetService("CrateService")
	self.DataController = knit.GetController("DataController")
	self.PanelController = knit.GetController("PanelController")
	self.HudController = knit.GetController("HudController")
	self.NotificationController = knit.GetController("NotificationController")
end

return CrateController
