local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PIXEL_SIZE = 5
local LETTER_GAP = 1
local DEFAULT_COLOR = Color3.new(1, 1, 1)
local DEFAULT_FONT = "Pixel"
local DEFAULT_ROTATION = Vector3.new(0, 0, 0)

local VortexFont = {}

local Billboards = {}
local StaticText = {}

local Module = ReplicatedStorage:WaitForChild("Fonts")
local Fonts = require(Module)

local SendBillboards = ReplicatedStorage:WaitForChild("SendBillboards") :: RemoteEvent

export type Font = "Pixel"

export type FontProps = {
	origin: Vector3,
	pixelSize: number?,
	color: Color3?,
	font: Font?,
	rotation: Vector3?,
	align: ("left" | "center" | "right")?,
}

local function createBlock(cframe: CFrame, size: Vector3, color: Color3, parent: Instance)
	local block = Instance.new("Part")
	block.Anchored = true
	block.Size = size
	block.Color = color
	block.CastShadow = false
	block.CanCollide = false
	block.CFrame = cframe
	block.Parent = parent
	return block
end

local function countBaselineRows(rows: { string })
	for i, row in ipairs(rows) do
		if string.find(row, "@", 1, true) then
			return #rows - i + 1
		end
	end
	return 0
end

local function calculateTotalWidth(characters, font_dir)
	local totalWidth = 0
	local characterWidths = {}

	for i, char in characters do
		local glyph = font_dir[char]
		local characterWidth = 0
		if glyph then
			for _, row in glyph do
				characterWidth = math.max(characterWidth, #row)
			end
		end
		characterWidths[i] = characterWidth
		totalWidth += characterWidth
		if i < #characters then
			totalWidth += LETTER_GAP
		end
	end
	return totalWidth, characterWidths
end

function VortexFont:DisplayText(props: FontProps, text: string, isBillboard: boolean)
	local color = props.color or DEFAULT_COLOR
	local font = props.font or DEFAULT_FONT
	local rot = props.rotation or DEFAULT_ROTATION
	local alignment = props.align or "left"
	local pixelSize = (props.pixelSize or PIXEL_SIZE) / Fonts[font].content_height

	local characters = string.split(string.upper(text), "")
	local font_dir = Fonts[font].characters

	local totalWidth, characterWidths = calculateTotalWidth(characters, font_dir)

	local alignOffset = 0
	if alignment == "center" then
		alignOffset = totalWidth / 2
	elseif alignment == "right" then
		alignOffset = totalWidth
	end
	local rotCFrame = CFrame.fromEulerAnglesXYZ(rot.X, rot.Y, rot.Z)
	local textGlyphs = {}
	local letterX = 0
	for i, char in characters do
		local glyph = font_dir[char]
		if glyph then
			for rowIndex, row in glyph do
				local y = #glyph - rowIndex - countBaselineRows(glyph) + 0.5

				for start, run in string.gmatch(row, "()([#@]+)") do
					local x = letterX + (start - 1) + #run / 2 - alignOffset
					local offset = Vector3.new(x, y, 0) * pixelSize
					local worldPos = props.origin + rotCFrame * offset
					local cframe = CFrame.new(worldPos) * rotCFrame.Rotation
					local size = Vector3.new(#run, 1, 1) * pixelSize

					table.insert(textGlyphs, createBlock(cframe, size, color, workspace))
				end
			end
		end
		letterX += characterWidths[i] + LETTER_GAP
	end

	return textGlyphs
end

-- StaticText functions
function VortexFont:UpdateText(id: string, changes: { [string]: any }, newText: string?)
	local entry = StaticText[id]
	if not entry then
		warn("VortexFont (UpdateText): Text '" .. id .. "' does not exist")
		return
	end
	for _, block in entry.blocks do
		block:Destroy()
	end
	for key, value in changes do
		entry.props[key] = value
	end
	if newText then
		entry.text = newText
	end
	entry.blocks = VortexFont:DisplayText(entry.props, entry.text, false)
end

function VortexFont:RemoveText(id: string)
	local entry = StaticText[id]
	if entry then
		for _, block in entry.blocks do
			block:Destroy()
		end
		StaticText[id] = nil
	end
end

function VortexFont:CreateText(props: FontProps, text: string, id: string)
	if StaticText[id] then
		VortexFont:RemoveText(id)
	end
	StaticText[id] = {
		props = props,
		text = text,
		blocks = VortexFont:DisplayText(props, text, false),
	}
end

-- Billboard functions
function VortexFont:CreateBillboard(props: FontProps, text: string, id: string)
	Billboards[id] = {
		origin = props.origin,
		pixelSize = props.pixelSize or PIXEL_SIZE,
		color = props.color or DEFAULT_COLOR,
		font = props.font or DEFAULT_FONT,
		text = text,
		align = props.align or "left",
		blocks = Billboards[id] and Billboards[id].blocks or {},
	}
	SendBillboards:FireAllClients(Billboards)
end

function VortexFont:UpdateBillboard(id: string, changes: { [string]: any })
	local billboard = Billboards[id]
	if not billboard then
		warn("VortexFont (UpdateBillboard): Billboard '" .. id .. "' does not exist")
	end
	for key, value in changes do
		billboard[key] = value
	end

	SendBillboards:FireAllClients(Billboards)
end

function VortexFont:RemoveBillboard(id: string)
	if Billboards[id] then
		for _, block in Billboards[id].blocks do
			block:Destroy()
		end
		Billboards[id] = nil
	end
	SendBillboards:FireAllClients(Billboards)
end

if RunService:IsServer() then
	Players.PlayerAdded:Connect(function(player)
		SendBillboards:FireClient(player, Billboards)
	end)
end

return VortexFont
