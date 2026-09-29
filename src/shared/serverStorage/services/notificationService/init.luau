-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local NotificationService = knit.CreateService({
	Name = "NotificationService",
	Client = { PushNotification = knit.CreateSignal() },
})

-- Public Methods
function NotificationService:PushNotification(player: Player, data: { Message: string, Color: Color3, Sound: string })
	self.Client.PushNotification:Fire(player, data)
end

return NotificationService
