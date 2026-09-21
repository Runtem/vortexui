local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Module = ReplicatedStorage:WaitForChild("VortexFont")
local VortexFont = require(Module)
local aura = 1000

local greetings = { "Say hi", "Greetings", "Welcome", "Bonjour" }

local props: VortexFont.FontProps = {
	origin = workspace.TestPart.Position + Vector3.new(0, 4, 0),
	pixelSize = 1.5,
	align = "center",
	color = Color3.fromRGB(0, 80, 0),
}

local props2: VortexFont.FontProps = {
	origin = workspace.TestPart.Position,
	pixelSize = 3,
	align = "center",
}

VortexFont:CreateText(props2, "Welcome to VortexFont!", "greeting")
VortexFont:CreateBillboard(props, "Aura: $" .. tostring(aura), "aura")

task.spawn(function()
	while true do
		local random = math.random(1, #greetings)
		local greeting = greetings[random]
		VortexFont:UpdateText("greeting", {}, greeting .. " to VortexFont!")
		task.wait(5)
	end
end)

task.wait(2)

task.spawn(function()
	while true do
		aura += 5
		VortexFont:UpdateBillboard("aura", {
			text = "Aura: $" .. tostring(aura),
			color = Color3.fromRGB(0, math.max(80 + math.floor(math.log(aura) * 10), 0), 0),
		})
		task.wait(0.01)
	end
end)