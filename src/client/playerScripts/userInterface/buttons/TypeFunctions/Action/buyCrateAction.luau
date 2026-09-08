-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
return function(button)
	local crateName = button.Parent.Parent:GetAttribute("CrateName")
	if typeof(crateName) ~= "string" then
		warn("Couldn't fetch CrateName")
		return
	end

	local amount = button:GetAttribute("Amount")
	if typeof(amount) ~= "number" then
		warn("Couldn't fetch Crate Amount Attribute")
		return
	end

	knit.GetController("CrateController"):OpenCrate(crateName, amount)
end
