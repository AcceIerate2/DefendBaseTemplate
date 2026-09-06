-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
return function(button)
	local crateName = button.Parent.Parent.Parent.Name

	knit.GetController("PanelController"):togglePanel("CrateInfo")
end
