-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
return function(button)
	local crateName = button.Parent.Parent.Parent.Name
	Players.LocalPlayer.PlayerGui:WaitForChild("Panels"):WaitForChild("CrateInfo"):SetAttribute("CrateName", crateName)
	knit.GetController("PanelController"):togglePanel("CrateInfo")
end
