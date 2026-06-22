local PropertyHelper = {}

local DEFAULT_INSTANCES = {}

function PropertyHelper.getDefault(className, property)
	if not DEFAULT_INSTANCES[className] then
		local success, inst = pcall(function() return Instance.new(className) end)
		if success then
			DEFAULT_INSTANCES[className] = inst
		else
			return nil
		end
	end
	
	local inst = DEFAULT_INSTANCES[className]
	if inst then
		local success, val = pcall(function() return inst[property] end)
		if success then
			return val
		end
	end
	return nil
end

local COMMON_PROPERTIES = {
	"Name", "Size", "Position", "AnchorPoint", "BackgroundColor3", 
	"BackgroundTransparency", "BorderColor3", "BorderSizePixel",
	"Rotation", "Visible", "ZIndex", "LayoutOrder", "ClipsDescendants",
	"AutoLocalize"
}

local CLASS_PROPERTIES = {
	TextLabel = {"Text", "TextColor3", "TextSize", "Font", "TextXAlignment", "TextYAlignment", "TextWrapped", "TextScaled", "TextTransparency", "RichText", "LineHeight", "MaxVisibleGraphemes"},
	TextButton = {"Text", "TextColor3", "TextSize", "Font", "TextXAlignment", "TextYAlignment", "TextWrapped", "TextScaled", "TextTransparency", "RichText", "AutoButtonColor"},
	TextBox = {"Text", "TextColor3", "TextSize", "Font", "TextXAlignment", "TextYAlignment", "TextWrapped", "TextScaled", "TextTransparency", "RichText", "ClearTextOnFocus", "MultiLine", "PlaceholderText", "PlaceholderColor3", "TextEditable"},
	ImageLabel = {"Image", "ImageColor3", "ImageTransparency", "ImageRectOffset", "ImageRectSize", "ScaleType", "SliceCenter", "SliceScale", "TileSize", "ResampleMode"},
	ImageButton = {"Image", "ImageColor3", "ImageTransparency", "ImageRectOffset", "ImageRectSize", "ScaleType", "SliceCenter", "SliceScale", "TileSize", "HoverImage", "PressedImage", "AutoButtonColor"},
	ScrollingFrame = {"CanvasPosition", "CanvasSize", "ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollBarThickness", "ScrollingDirection", "ElasticBehavior", "HorizontalScrollBarInset", "VerticalScrollBarInset"},
	UIListLayout = {"Padding", "FillDirection", "HorizontalAlignment", "VerticalAlignment", "SortOrder"},
	UIGridLayout = {"CellPadding", "CellSize", "FillDirection", "HorizontalAlignment", "VerticalAlignment", "SortOrder", "StartCorner"},
	UIPadding = {"PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"},
	UICorner = {"CornerRadius"},
	UIStroke = {"ApplyStrokeMode", "Color", "LineJoinMode", "Thickness", "Transparency"},
	UIGradient = {"Color", "Offset", "Rotation", "Transparency"},
	UIAspectRatioConstraint = {"AspectRatio", "AspectType", "DominantAxis"},
	UITextSizeConstraint = {"MaxTextSize", "MinTextSize"},
	UISizeConstraint = {"MaxSize", "MinSize"}
}

function PropertyHelper.getProperties(className)
	local props = {}
	for _, p in ipairs(COMMON_PROPERTIES) do
		table.insert(props, p)
	end
	if CLASS_PROPERTIES[className] then
		for _, p in ipairs(CLASS_PROPERTIES[className]) do
			table.insert(props, p)
		end
	end
	return props
end

function PropertyHelper.formatValue(value)
	local t = typeof(value)
	if t == "string" then
		return string.format("%q", value)
	elseif t == "number" then
		if value == math.floor(value) then
			return tostring(value)
		end
		
		if math.abs(value - math.round(value)) < 0.001 then
			return tostring(math.round(value))
		end
		
		local rounded = math.round(value * 1000) / 1000
		return tostring(rounded)
	elseif t == "boolean" then
		return tostring(value)
	elseif t == "UDim2" then
		if value.X.Offset == 0 and value.Y.Offset == 0 then
			return string.format("UDim2.fromScale(%s, %s)", PropertyHelper.formatValue(value.X.Scale), PropertyHelper.formatValue(value.Y.Scale))
		elseif value.X.Scale == 0 and value.Y.Scale == 0 then
			return string.format("UDim2.fromOffset(%s, %s)", PropertyHelper.formatValue(value.X.Offset), PropertyHelper.formatValue(value.Y.Offset))
		end
		return string.format("UDim2.new(%s, %s, %s, %s)", PropertyHelper.formatValue(value.X.Scale), PropertyHelper.formatValue(value.X.Offset), PropertyHelper.formatValue(value.Y.Scale), PropertyHelper.formatValue(value.Y.Offset))
	elseif t == "UDim" then
		return string.format("UDim.new(%s, %s)", PropertyHelper.formatValue(value.Scale), PropertyHelper.formatValue(value.Offset))
	elseif t == "Color3" then
		return string.format("Color3.fromRGB(%d, %d, %d)", math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255))
	elseif t == "Vector2" then
		return string.format("Vector2.new(%s, %s)", PropertyHelper.formatValue(value.X), PropertyHelper.formatValue(value.Y))
	elseif t == "Vector3" then
		return string.format("Vector3.new(%s, %s, %s)", PropertyHelper.formatValue(value.X), PropertyHelper.formatValue(value.Y), PropertyHelper.formatValue(value.Z))
	elseif t == "Rect" then
		return string.format("Rect.new(%s, %s, %s, %s)", PropertyHelper.formatValue(value.Min.X), PropertyHelper.formatValue(value.Min.Y), PropertyHelper.formatValue(value.Max.X), PropertyHelper.formatValue(value.Max.Y))
	elseif t == "Font" then
		return string.format("Font.new(%q, Enum.FontWeight.%s, Enum.FontStyle.%s)", value.Family, value.Weight.Name, value.Style.Name)
	elseif t == "ColorSequence" then
		if #value.Keypoints == 1 or (#value.Keypoints == 2 and value.Keypoints[1].Value == value.Keypoints[2].Value) then
			return string.format("ColorSequence.new(%s)", PropertyHelper.formatValue(value.Keypoints[1].Value))
		end
		local kps = {}
		for _, kp in ipairs(value.Keypoints) do
			table.insert(kps, string.format("ColorSequenceKeypoint.new(%s, %s)", PropertyHelper.formatValue(kp.Time), PropertyHelper.formatValue(kp.Value)))
		end
		return string.format("ColorSequence.new({\n\t\t%s\n\t})", table.concat(kps, ",\n\t\t"))
	elseif t == "NumberSequence" then
		if #value.Keypoints == 1 or (#value.Keypoints == 2 and value.Keypoints[1].Value == value.Keypoints[2].Value) then
			return string.format("NumberSequence.new(%s)", PropertyHelper.formatValue(value.Keypoints[1].Value))
		end
		local kps = {}
		for _, kp in ipairs(value.Keypoints) do
			table.insert(kps, string.format("NumberSequenceKeypoint.new(%s, %s, %s)", PropertyHelper.formatValue(kp.Time), PropertyHelper.formatValue(kp.Value), PropertyHelper.formatValue(kp.Envelope)))
		end
		return string.format("NumberSequence.new({\n\t\t%s\n\t})", table.concat(kps, ",\n\t\t"))
	elseif t == "NumberRange" then
		return string.format("NumberRange.new(%s, %s)", PropertyHelper.formatValue(value.Min), PropertyHelper.formatValue(value.Max))
	elseif t == "EnumItem" then
		return tostring(value)
	end
	return string.format("%q", tostring(value))
end

return PropertyHelper
