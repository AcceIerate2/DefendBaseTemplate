-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

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
	PlaceId = 91322815196905,
	PlayersInTeleportQueue = {},
	MaxPlayers = 4,
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
	print("Teleporting Players To Server")
	local players = table.clone(self.Queues[id])
	self.Queues[id] = {}

	for _, player: Player in pairs(players) do
		table.insert(self.PlayersInTeleportQueue, player)
	end

	local status, accessCode = pcall(function()
		return TeleportService:ReserveServerAsync(self.PlaceId)
	end)

	if not status then
		for _, player: Player in pairs(players) do
			self:RemovePlayerFromTeleportQueue(player)
		end

		warn(accessCode)
		return
	end

	TeleportService:TeleportToPrivateServer(self.PlaceId, accessCode, players)
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
				local index = table.find(playersInHitbox, player)
				if index then
					table.remove(playersInHitbox, index)
				end
			end

			-- Detect Changes
			-- Detect Player Joins
			local toRemove = {}
			for index, playerInHitbox: Player in pairs(playersInHitbox) do
				if table.find(self.Queues[id], playerInHitbox) then
				-- Player already in queue
				elseif
					#self.Queues[id] >= self.MaxPlayers
					and not table.find(self.Queues[id], playerInHitbox)
					and not table.find(self.PlayersInTeleportQueue, playerInHitbox)
				then
					table.insert(toRemove, index)
					-- Queue Full
				end
			end

			for index = #toRemove, 1, -1 do
				table.remove(playersInHitbox, toRemove[index])
			end

			while #playersInHitbox > self.MaxPlayers do
				table.remove(playersInHitbox)
			end

			-- Detect Player Exits
			for _, playerInQueue in pairs(self.Queues[id]) do
				if not table.find(playersInHitbox, playerInQueue) then
					-- Player Left
				end
			end

			-- Update Queues Table
			self.Queues[id] = playersInHitbox
			if #self.Queues[id] >= self.MaxPlayers then
			end

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
	end)
end

-- Public Methods
function MatchMakingService:RemovePlayerFromTeleportQueue(player: Player)
	local index = table.find(self.PlayersInTeleportQueue, player)
	if index then
		table.remove(self.PlayersInTeleportQueue, index)
	end
end

-- LifeCycle
function MatchMakingService:KnitStart()
	self:listenToHitboxes()
	TeleportService.TeleportInitFailed:Connect(function(player: Player)
		self:RemovePlayerFromTeleportQueue(player)
	end)
end

return MatchMakingService
