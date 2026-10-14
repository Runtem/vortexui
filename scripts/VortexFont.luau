


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
local ColorModule=require(ReplicatedStorage:WaitForChild("ColorModule"))

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

-- effects = { [string] = { open = function(args, props), close = function(args, props) } }
-- open = <MARKUPID=arg>
-- close = </MARKUPID>
local effects = {
	color = {
		open = function(args, props) 
			local hex = args[1]
			if hex then 
				hex = hex:gsub("^#", "") 
					props.Color = ColorModule.fromHex(hex) 
			end 
		end,
		close = function(args, props)
			props.Color = nil  
		end,
	}, 
	size = {
		open = function(args, props) 
			local number = tonumber(args[1])
			if number then 
			    props.Size=number

			end 
		end,
		close = function(args, props)
			    props.Size=nil
		end,
	}, 
	font = {
		open = function(args, props) 
			local font = args[1]
			if number then 
			    props.Font=font

			end 
		end,
		close = function(args, props)
			    props.Font=nil
		end,
	}, 
	transparency = {
		open = function(args, props) 
			local number = tonumber(args[1])
			if number then 
			    props.Transparency=number

			end 
		end,
		close = function(args, props)
			    props.Transparency=nil
		end,
	}, 
}

local function parse_tag(tag)
	local is_closing = tag:sub(1, 1) == "/"
	if is_closing then
		tag = tag:sub(2)
	end
	
	local name, argstr = tag:match("^(%w+)[=:]?(.*)$")
	if not name then return nil end

	local args = {}
	if argstr and argstr ~= "" then
		for a in argstr:gmatch("[^,;%s]+") do
			table.insert(args, a)
		end
	end

	return {
		name = name:lower(),
		args = args,
		closing = is_closing,
	}
end

-- Returns a list of segments: { text = "...", props = { any } }
local function parse_rich_text(input)
	local segments = {}
	local active = {}         
	local currentProps = {}    -- current property table

	local function push_segment(text)
		if text == "" then return end
		-- deep-ish copy  
		local propsCopy = {}
		for k, v in pairs(currentProps) do
			propsCopy[k] = v
		end
		table.insert(segments, {
			text = text,
			props = propsCopy,
		})
	end

	local pos = 1
	while pos <= #input do
		local tag_start, tag_end, tag_content = input:find("<(.-)>", pos)

		if not tag_start then
			push_segment(input:sub(pos))
			break
		end
 
		if tag_start > pos then
			push_segment(input:sub(pos, tag_start - 1))
		end

		local tag = parse_tag(tag_content)
		if tag then
			local effect = effects[tag.name]
			if effect then
				if tag.closing then -- on </MARKUPID>
					for i = #active, 1, -1 do
						if active[i].name == tag.name then 
							effect.close(active[i].args, currentProps) -- run close() function
							table.remove(active, i)
							break
						end
					end
				else  -- on <MARKUPID=args>
					effect.open(tag.args, currentProps)
					table.insert(active, {
						name = tag.name,
						args = tag.args,
						effect = effect,
					})
				end
			end
		end

		pos = tag_end + 1
	end

	return segments
end


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

	local characters = string.split( text , "")
	local font_dir = Fonts[font].characters

	local totalWidth, characterWidths = calculateTotalWidth(characters, font_dir)

	local alignOffset = 0
	 
	local rotCFrame = CFrame.fromEulerAnglesXYZ(rot.X, rot.Y, rot.Z)  
	local segments = {{
			text = text,
			props = {},
			}}
			if props.richtext then
			    segments=parse_rich_text(text)
			   end
  
	local allCharacters = {}
	for _, seg in ipairs(segments) do
		for char in seg.text:gmatch(".") do
			table.insert(allCharacters, char)
		end
	end

	totalWidth, characterWidths = calculateTotalWidth(allCharacters, font_dir)

	if alignment == "center" then
		alignOffset = totalWidth / 2
	elseif alignment == "right" then
		alignOffset = totalWidth
	end

	local textGlyphs = {}
	local letterX = 0
	local charIndex = 0  

	for _, segment in ipairs(segments) do
		local segmentColor = segment.props.Color or color
		-- local segmentSize = segment.props.Size or pixelSize --idk how to calculate ts :(
		local segmentTransparency = segment.props.Transparency or 0
		-- local segmentFont = segment.props.Font or font --idk how to calculate ts :(

		for char in segment.text:gmatch(".") do
			charIndex += 1
			local glyph = font_dir[char] 
			-- or DEFAULT_FONT[char] --fallback to the default font that has the character
			-- or font_dir['¿'] or DEFAULT_FONT['¿'] -- no character symbol t --idk how to calculate ts :(
			
			if glyph then
				for rowIndex, row in glyph do
					local y = #glyph - rowIndex - countBaselineRows(glyph) + 0.5

					for start, run in string.gmatch(row, "()([#@]+)") do
						local x = letterX + (start - 1) + #run / 2 - alignOffset
						local offset = Vector3.new(x, y, 0) * pixelSize
						local worldPos = props.origin + rotCFrame * offset
						local cframe = CFrame.new(worldPos) * rotCFrame.Rotation
						local size = Vector3.new(#run, 1, 1) * pixelSize

						local Block=createBlock(cframe, size, segmentColor, workspace)
						Block.Transparency=segmentTransparency--might want to migrate this to createblock()
						
						table.insert(textGlyphs, Block)
					end
					end 
			end
			letterX += characterWidths[charIndex] + LETTER_GAP
		end
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
