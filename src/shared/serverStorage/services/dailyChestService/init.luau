-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local SafeFunctionCaller = require(ReplicatedStorage.src.utility.SafeFunctionCaller)

-- Constants
local chestPrompt = workspace.ChestPrompt
local groupId = 1001559608
local reward = 10
local rewardType = "Coins"
local secondsInADay = 86400

-->
local DailyChestService = knit.CreateService({
	Name = "DailyChestService",
})

-- Private Methods
function DailyChestService:notifyPlayer(player: Player, message: string, color: Color3, sound: string)
	self.NotificationService:PushNotification(player, {
		Message = message,
		Color = color,
		Sound = sound,
	})
end

function DailyChestService:isInGroup(player: Player)
	local status, response = SafeFunctionCaller(player.IsInGroupAsync, player, groupId)
	return status and response or false
end

function DailyChestService:rewardPlayer(player: Player)
	local valueObject = self.DataService:GetValueObject(player, rewardType)
	valueObject:Set(valueObject:Get() + reward)
end

function DailyChestService:claimedForTheDay(player: Player)
	local lastClaimedGroupChest = self.DataService:GetValue(player, "LastClaimedGroupChest")
	local secondsSinceThen = os.time() - lastClaimedGroupChest
	return secondsSinceThen < secondsInADay
end

-- LifeCycle
function DailyChestService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.NotificationService = knit.GetService("NotificationService")
end

function DailyChestService:KnitStart()
	local prompt = InstanceCreator("ProximityPrompt", "ProximityPrompt", chestPrompt, {
		ActionText = "Claim",
	}) :: ProximityPrompt

	prompt.Triggered:Connect(function(playerWhoTriggered: Player)
		if not self:isInGroup(playerWhoTriggered) then
			self:notifyPlayer(
				playerWhoTriggered,
				"You need to join the group first!",
				Color3.fromRGB(255, 0, 0),
				"Decline"
			)
			return
		end

		if self:claimedForTheDay(playerWhoTriggered) then
			self:notifyPlayer(
				playerWhoTriggered,
				"You already claimed your reward!",
				Color3.fromRGB(255, 0, 0),
				"Decline"
			)
			return
		end

		self:rewardPlayer(playerWhoTriggered)
		self.DataService:GetValueObject(playerWhoTriggered, "LastClaimedGroupChest"):Set(os.time() + secondsInADay)

		self:notifyPlayer(playerWhoTriggered, `Claimed +{reward} {rewardType}`, Color3.fromRGB(0, 255, 0), "Accept")
		return
	end)
end

return DailyChestService
