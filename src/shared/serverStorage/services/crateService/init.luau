-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config Modules
local cratesConfig = require(ReplicatedStorage.src.GameConfiguration.General.cratesConfig)

-- Constants
local Random = Random.new()

-->
local CrateService = knit.CreateService({
	Name = "CrateService",
})

-- Client Exposed Methods
function CrateService.Client:OpenCrate(player: Player, crateName: string, amount: number)
	return self.Server:OpenCrate(player, crateName, amount)
end

-- Private Methods
function CrateService:rngItem(items: { [string]: number }): string?
	local totalWeight = 0

	for _, weight in pairs(items) do
		totalWeight += weight
	end

	local roll = Random:NextInteger(1, totalWeight)
	local currentWeight = 0

	for itemName, weight in pairs(items) do
		currentWeight += weight

		if roll <= currentWeight then
			return itemName
		end
	end

	return nil
end

-- Public Methods
function CrateService:OpenCrate(player: Player, crateName: string, amount: number)
	local crateConfig = cratesConfig[crateName]
	if not crateConfig then
		return {
			Status = false,
			Reason = "Something went wrong, try again.",
		}
	end

	local cost = crateConfig.Cost * amount
	if self.DataService:GetValue(player, "Coins") < cost then
		return {
			Status = false,
			Reason = `You need ${NumberShortner(self.DataService:GetValue(player, "Cash") - cost)} more!`,
		}
	end

	self.DataService:GetValueObject(player, "Coins"):Set(self.DataService:GetValue(player, "Coins") - cost)
	
	local items = {}
	for i = amount, 1, -1 do
		items[i] = self:rngItem(crateConfig.Items)
	end

	return { Status = true, Items = items}
end

-- LifeCycle
function CrateService:KnitInit()
	self.DataService = knit.GetService("DataService")
end

return CrateService
