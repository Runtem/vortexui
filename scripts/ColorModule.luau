-- Credit to @Azurii#2276 for this module
local clamp = math.clamp
local abs = math.abs
local round = math.round
local format = string.format

local Colors = {}

local function hueToRGB(hue)
	local h = hue * 6 % 6
	return clamp(abs(h - 3) - 1, 0, 1), clamp(2 - abs(h - 2), 0, 1), clamp(2 - abs(h - 4), 0, 1)
end

-- Palette functions
function Colors.fromHue(hue)
	local r, g, b = hueToRGB(hue)
	return Color3.new(0.27 + 0.63 * r, 0.27 + 0.63 * g, 0.27 + 0.63 * b)
end

function Colors.varied(hue, shift)
	return Colors.fromHue(hue + (math.random() * 2 - 1) * shift)
end

-- HSV functions
function Colors.fromHSV(h, s, v)
	local r, g, b = hueToRGB(h)
	return Color3.new(v * (1 + s * (r - 1)), v * (1 + s * (g - 1)), v * (1 + s * (b - 1)))
end

function Colors.toHSV(color)
	local r, g, b = color.R, color.G, color.B
	local max = math.max(r, g, b)
	local d = max - math.min(r, g, b)
	local h = 0
	if d > 0 then
		if max == r then
			h = (g - b) / d % 6
		elseif max == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
	end
	return h / 6, max == 0 and 0 or d / max, max
end

-- Hex functions
function Colors.fromHex(hex)
	local s = hex:gsub("#", "")
	if #s == 3 then
		s = s:gsub("%x", "%0%0")
	end
	local n = tonumber(s, 16)
	return Color3.fromRGB(n // 65536, n // 256 % 256, n % 256)
end

function Colors.toHex(color)
	return format("%02X%02X%02X", round(color.R * 255), round(color.G * 255), round(color.B * 255))
end

return Colors
