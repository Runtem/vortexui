local PIXEL_SIZE = 1
local LETTER_WIDTH = 5
local LETTER_GAP = 1
local DEFAULT_COLOR = Color3.new(1, 1, 1)
local DEFAULT_FONT = "Pixel"

local VortexFont = {}
local Fonts = require(script.Parent.Fonts)

export type Font = "Pixel"

export type FontProps = {
    origin: Vector3,
    pixelSize: number?,
    color: Color3?,
    font: Font?
}

local function createBlock(position: Vector3, size: Vector3, color: Color3, parent: Instance)
	local block = Instance.new("Part")
	block.Anchored = true
	block.Size = size
	block.Position = position
	block.Color = color
	block.Parent = parent
	block.CastShadow = false
	return block
end

function VortexFont:DisplayText(props: FontProps, text: string)
	local pixelSize = props.pixelSize or PIXEL_SIZE
	local color = props.color or DEFAULT_COLOR
	local font = props.font or DEFAULT_FONT
	
	local model = Instance.new("Model", workspace)
	for i, char in string.split(string.upper(text), "") do
	    local font_dir = Fonts[font]
		local glyph = font_dir[char]
		if glyph then
			local letterX = (i - 1) * (LETTER_WIDTH + LETTER_GAP)

			for rowIndex, row in glyph do
				local y = #glyph - rowIndex + 0.5
				
				for start, run in string.gmatch(row, "()(#+)") do
					local x = letterX + (start - 1) + #run / 2
					local position = props.origin + Vector3.new(x, y, 0) * pixelSize
					local size = Vector3.new(#run, 1, 1) * pixelSize
					createBlock(position, size, color, model)
				end
			end
		end
	end

	return model
end

return VortexFont