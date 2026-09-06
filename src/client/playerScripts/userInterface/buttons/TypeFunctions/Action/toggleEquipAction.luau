-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
return function(button: GuiButton)
	knit.GetController("InventoryController"):ToggleEquip(button:GetAttribute("ItemName"))
end
