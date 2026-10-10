local classFunctions = {}

local TextLabel = {}
TextLabel.__index = classFunctions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mod = ReplicatedStorage["3Dgui"]

local vortexFont = require(ReplicatedStorage.VortexFont)

function TextLabel.new(parent)
    local self = setmetatable({}, TextLabel)
    self.Size = Vector3.new(200, 50, 0) -- has to use Vector3 cause no support for Vector2
    self.Position = Vector3.new(0, 0, 0) -- starts from center cause i dont know the screen size
    self.BackgroundColor3 = Color3.new(1, 1, 1) -- white
    self.BackgroundTransparency = 0
    self.Parent = parent
    self.Children = {}
    self.Visible = true
    self.Rotation = 0
    self.ZIndex = 0
    self.ClassName = "TextLabel"
    self.Text = "Label"
    self.TextColor3 = Color3.new(0, 0, 0)
    self.TextSize = 14
    self.id = math.random(-500000, 500000)
    self.Font = "Pixel"
    self.Name = "TextLabel"
    self.TextAlign='center'
    self.RichText=false
    
    local props: VortexFont.Font = {
        origin = workspace.Baseplate.Position,
		pixelSize = self.TextSize / 100,
		color = self.TextColor3,
		rotation = Vector3.new(0, 0, math.rad(self.Rotation)),
		align = self.TextAlign,
 	   richtext=self.RichText,
    }
    
    vortexFont:CreateText(props, self.Text, self.id)
    
    return self
end

function classFunctions:Clone()
    local clone = TextLabel.new()
    clone.Size = self.Size
    clone.Position = self.Position
    clone.Visible = self.Visible
    clone.Rotation = self.Rotation
    clone.BackgroundColor3 = self.BackgroundColor3
    clone.BackgroundTransparency = self.BackgroundTransparency
    clone.ZIndex = self.ZIndex
    clone.Name = self.Name
    clone.Font = self.Font
    clone.TextSize = self.TextSize
    clone.TextColor3 = self.TextColor3
    clone.Text = self.Text
    clone.TextAlign= self.TextAlign 
    clone.RichText= self.RichText 
    
    return clone
end

function classFunctions:GetCFrame(parent, finalCFrame, z)
    local newZ = 0
    if z == nil then
        z = -3 - (self.ZIndex * 0.011)
    	if mod:FindFirstChild("Sibling") then
        	if parent ~= nil then
           	 z = -3 - ((parent.ZIndex * 0.011) - (self.ZIndex * 0.011)) + 0.011
       	 end
    	end
    else
        newZ -= (self.ZIndex * 0.011)
        if mod:FindFirstChild("Sibling") then
        	if parent ~= nil then
           	 newZ += 0.011
       	 end
    	end
    end
    
    local camera = workspace.CurrentCamera
	if finalCFrame == nil then
	    finalCFrame = camera.CFrame * CFrame.new(self.Position.X / 100, self.Position.Y / 100, z)
	else
	    finalCFrame *= CFrame.new(0, 0, newZ)
	end
	
	
	if parent then
	    finalCFrame *= CFrame.Angles(0, 0, math.rad(parent.Rotation)) * CFrame.new(parent.Position.X / 100, parent.Position.Y / 100, 0)
	    if parent.ClassName == "ScrollingFrame" then
    	    finalCFrame *= CFrame.new(-parent.CanvasPosition.X / 100, -parent.CanvasPosition.Y / 100, 0)
    	end
	    
	    if parent.Parent then
	        return parent:GetCFrame(parent.Parent, finalCFrame, z)
	    end
	end
	return finalCFrame
end

function classFunctions:Draw()
    if self.Visible == true then
        local camera = workspace.CurrentCamera
        local parent = self.Parent
        
        local z = -3 - (self.ZIndex * 0.011)
        if mod:FindFirstChild("Sibling") then
            if parent then
                z = -3 - ((parent.ZIndex * 0.011) - (self.ZIndex * 0.011)) + 0.011
            end
        end
        
        local finalCFrame = self:GetCFrame(parent)
* CFrame.Angles(0, 0, math.rad(self.Rotation))
        
    	local frame = Instance.new("Part")
    	frame.Size = Vector3.new(self.Size.X / 100, self.Size.Y / 100, 0.02)
    	frame.CFrame = finalCFrame
		frame.Color = self.BackgroundColor3
    	frame.Anchored = true
    	frame.CanCollide = false
    	frame.CastShadow = false
    	frame.Transparency = self.BackgroundTransparency
    	frame.Parent = workspace:WaitForChild("3Dgui UIs")
    	
    	local y, x, z = finalCFrame:ToEulerAnglesXYZ()
    	
    	local props: VortexFont.Font = {
        	origin = (finalCFrame * CFrame.new(0, -(self.Size.Y / (7 / (self.TextSize / 14))) / 100, 0.01)).Position,
			pixelSize = self.TextSize / 100,
			color = self.TextColor3,
			rotation = Vector3.new(y, x, z), 
			align = self.TextAlign,
			richtext=self.RichText
    	}
    	
    	vortexFont:UpdateText(self.id, props, self.Text)
    end
end

return TextLabel
