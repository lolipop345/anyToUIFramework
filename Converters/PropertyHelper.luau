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
		return tostring(math.round(value * 1000) / 1000)
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
	elseif t == "EnumItem" then
		return tostring(value)
	end
	return string.format("%q", tostring(value))
end

return PropertyHelper
