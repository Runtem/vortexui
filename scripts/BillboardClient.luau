local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Module = ReplicatedStorage:WaitForChild("VortexFont")
local VortexFont = require(Module)

local SendBillboards = ReplicatedStorage:WaitForChild("SendBillboards") :: RemoteEvent

local Billboards = {}

function updateBillboards()
	local camera = workspace.CurrentCamera
	for k, billboard in pairs(Billboards) do
		for i, v in ipairs(billboard.blocks) do
			v:Destroy()
		end
		local props: VortexFont.FontProps = {
			origin = billboard.origin,
			pixelSize = billboard.pixelSize,
			color = billboard.color,
			font = billboard.font,
			align = billboard.align,
			rotation = Vector3.new(camera.CFrame:ToEulerAnglesXYZ()),
		}
		billboard.blocks = VortexFont:DisplayText(props, billboard.text, true)
	end
end

SendBillboards.OnClientEvent:Connect(function(billboards)
	for id, old in pairs(Billboards) do
		if not billboards[id] then
			for _, v in ipairs(old.blocks) do
				v:Destroy()
			end
		end
	end
	for id, new in pairs(billboards) do
		new.blocks = Billboards[id] and Billboards[id].blocks or {}
	end
	Billboards = billboards
end)

RunService.Heartbeat:Connect(function()
	updateBillboards()
end)
