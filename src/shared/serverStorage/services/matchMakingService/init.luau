-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)

-- Constants
local MatchHitboxes = workspace.MatchHitboxes

-- Helper Functions
local function getPlayersInHitbox(hitbox: BasePart): { Player? }
	local players = {}
	for _, part in pairs(workspace:GetPartsInPart(hitbox)) do
		local player = Players:GetPlayerFromCharacter(partOfCharacter(part))
		if player and player:IsA("Player") and not table.find(players, player) then
			table.insert(players, player)
		end
	end
	return players
end

-->
local MatchMakingService = knit.CreateService({
	Name = "MatchMakingService",
	PlayersInTeleportQueue = {},
	Queues = (function()
		local tableToReturn = {}
		for _, hitbox in pairs(MatchHitboxes:GetChildren()) do
			tableToReturn[tonumber(hitbox.Name)] = {}
		end
		return tableToReturn
	end)(),
})

-- Private Methods
function MatchMakingService:teleportPlayers(id: number)
	print("Telporting Players To Server")
	local players = table.clone(self.Queues[id])
	self.Queues[id] = {}

	for _, player: Player in pairs(players) do
		table.insert(self.PlayersInTeleportQueue, player)
	end
end

function MatchMakingService:listenToHitboxes()
	local countdowns = {}
	local elapsed = 0

	RunService.Heartbeat:Connect(function(deltaTime: number)
		for _, hitbox in pairs(MatchHitboxes:GetChildren()) do
			local id = tonumber(hitbox.Name)
			local playersInHitbox = getPlayersInHitbox(hitbox)

			-- Remove Players In Teleport Queue
			for _, player: Player in pairs(self.PlayersInTeleportQueue) do
			end

			-- Detect Changes
			-- Detect Player Joins
			local toRemove = {}
			for index, playerInHitbox: Player in pairs(playersInHitbox) do
				if table.find(self.Queues[id], playerInHitbox) then
					-- Player Joined
				elseif
					#self.Queues[id] >= 1
					and not table.find(self.Queues[id], playerInHitbox)
					and not table.find(self.PlayersInTeleportQueue, playerInHitbox)
				then
					table.insert(toRemove, index)
					-- Queue Full
				end
			end

			for _, index in pairs(toRemove) do
				playersInHitbox[index] = nil
			end

			-- Detect Player Exits
			for _, playerInQueue in pairs(self.Queues[id]) do
				if not table.find(playersInHitbox, playerInQueue) then
					-- Player Left
				end
			end

			-- Update Queues Table
			self.Queues[id] = playersInHitbox
			if #self.Queues[id] > 0 then
				if not countdowns[id] then
					countdowns[id] = 10
				end
			else
				countdowns[id] = nil
			end
		end

		-- Skip Every Second
		elapsed += deltaTime
		if elapsed < 1 then
			return
		end
		elapsed = 0

		-- Update Countdowns
		for id: number, secondsLeft: number in pairs(countdowns) do
			countdowns[id] -= 1
			if countdowns[id] == 0 and #self.Queues[id] > 0 then
				self:teleportPlayers(id)
				countdowns[id] = nil
			end
		end

		print(self.Queues)
		print(countdowns)
	end)
end

-- LifeCycle
function MatchMakingService:KnitStart()
	self:listenToHitboxes()
end

return MatchMakingService
