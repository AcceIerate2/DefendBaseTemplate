-->
local AxeHandlerTemplate = {
}

function AxeHandlerTemplate:Bind(tool: Tool)
	tool.Equipped:Connect(function()
	end)

	tool.Unequipped:Connect(function()
	end)
end

function AxeHandlerTemplate:Disconnect()
end

return AxeHandlerTemplate
