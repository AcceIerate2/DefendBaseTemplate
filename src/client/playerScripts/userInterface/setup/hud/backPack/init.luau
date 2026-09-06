local BackPack = {}

-->
function BackPack:syncCard() end

function BackPack:preloadCards()
	for i = 5, 1, -1 do
		local newCard = self.Template:Clone()
		newCard.Visible = true
		newCard.Name = `{i}`
		newCard.LayoutOrder = i

		newCard:AddTag("GuiButton")
		newCard:SetAttribute("Type", "Action")
		newCard:SetAttribute("Action", "")

		newCard.Parent = self.Container
	end
end

-- LifeCycle
function BackPack:Init(player: Player)
	self.Container = player.PlayerGui:WaitForChild("BackPack"):WaitForChild("Container")
	self.Template = self.Container:WaitForChild("Template")
	self.Template.Visible = false
	self:preloadCards()
end

return BackPack
