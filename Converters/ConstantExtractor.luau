local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))

local ConstantExtractor = {}

-- Weights for heuristic algorithm
local TYPE_WEIGHTS = {
	ColorSequence = 10,
	NumberSequence = 10,
	Font = 5,
	Color3 = 4,
	UDim2 = 3,
	UDim = 2,
	Vector2 = 3,
	Vector3 = 3,
	Rect = 4,
	NumberRange = 4,
	string = 1 -- evaluated by length
}

local function isClose(a, b)
	return math.abs(a - b) < 0.001
end

local function getSmartName(propName, t, val)
	if t == "Color3" then
		if isClose(val.R, 1) and isClose(val.G, 1) and isClose(val.B, 1) then return "COLOR_WHITE" end
		if isClose(val.R, 0) and isClose(val.G, 0) and isClose(val.B, 0) then return "COLOR_BLACK" end
		local context = propName:match("Color") and propName:gsub("3$", "") or (propName .. "Color")
		return context:upper()
	elseif t == "UDim2" then
		if isClose(val.X.Scale, 1) and isClose(val.X.Offset, 0) and isClose(val.Y.Scale, 1) and isClose(val.Y.Offset, 0) then return "SIZE_FULL" end
		if isClose(val.X.Scale, 1) and isClose(val.X.Offset, 0) and isClose(val.Y.Scale, 0) and isClose(val.Y.Offset, 0) then return "SIZE_WIDTH" end
		if isClose(val.X.Scale, 0) and isClose(val.X.Offset, 0) and isClose(val.Y.Scale, 1) and isClose(val.Y.Offset, 0) then return "SIZE_HEIGHT" end
		if isClose(val.X.Scale, 0) and isClose(val.X.Offset, 0) and isClose(val.Y.Scale, 0) and isClose(val.Y.Offset, 0) then return "UDIM2_ZERO" end
		local context = propName:match("Size") and "SIZE" or (propName:match("Position") and "POS" or "UDIM2")
		return context
	elseif t == "Font" then
		local family = val.Family:match("([^/]+)$") or "FONT"
		return "FONT_" .. family:upper():gsub("[^%w]", "")
	elseif t == "string" then
		local clean = val:sub(1, 10):upper():gsub("[^%w]", "")
		if clean == "" then clean = "STR" end
		return "TEXT_" .. clean
	end
	return t:upper()
end

local function calculateComplexity(t, val)
	local base = TYPE_WEIGHTS[t] or 0
	if t == "string" then
		base = math.max(0, math.floor(#val / 10))
	elseif t == "UDim2" then
		if val.X.Scale ~= 0 and val.X.Offset ~= 0 then base = base + 2 end
		if val.Y.Scale ~= 0 and val.Y.Offset ~= 0 then base = base + 2 end
	end
	return base
end

local function traverseAndProfile(node, profiles)
	if node.Properties then
		for propName, val in pairs(node.Properties) do
			local t = typeof(val)
			if TYPE_WEIGHTS[t] then
				local formatted = PropertyHelper.formatValue(val)
				if not profiles[formatted] then
					profiles[formatted] = { Type = t, Value = val, Frequency = 0, Props = {} }
				end
				profiles[formatted].Frequency = profiles[formatted].Frequency + 1
				profiles[formatted].Props[propName] = (profiles[formatted].Props[propName] or 0) + 1
			end
		end
	end
	
	if node.Type == "ComponentCall" and node.Props then
		for pName, pVal in pairs(node.Props) do
			local t = typeof(pVal)
			if TYPE_WEIGHTS[t] then
				local formatted = PropertyHelper.formatValue(pVal)
				if not profiles[formatted] then
					profiles[formatted] = { Type = t, Value = pVal, Frequency = 0, Props = {} }
				end
				profiles[formatted].Frequency = profiles[formatted].Frequency + 1
				profiles[formatted].Props[pName] = (profiles[formatted].Props[pName] or 0) + 1
			end
		end
	end

	if node.Children then
		for _, child in ipairs(node.Children or {}) do
			traverseAndProfile(child, profiles)
		end
	end
end

local function traverseAndReplace(node, constantMap)
	if node.Properties then
		for propName, val in pairs(node.Properties) do
			local t = typeof(val)
			if TYPE_WEIGHTS[t] then
				local formatted = PropertyHelper.formatValue(val)
				if constantMap[formatted] then
					node.Properties[propName] = { Type = "LocalVariable", Name = constantMap[formatted] }
				end
			end
		end
	end
	
	if node.Type == "ComponentCall" and node.Props then
		for pName, pVal in pairs(node.Props) do
			local t = typeof(pVal)
			if TYPE_WEIGHTS[t] then
				local formatted = PropertyHelper.formatValue(pVal)
				if constantMap[formatted] then
					node.Props[pName] = { Type = "LocalVariable", Name = constantMap[formatted] }
				end
			end
		end
	end

	if node.Children then
		for _, child in ipairs(node.Children or {}) do
			traverseAndReplace(child, constantMap)
		end
	end
end

function ConstantExtractor.extract(roots, components)
	local profiles = {}
	
	for _, root in ipairs(roots) do
		traverseAndProfile(root, profiles)
	end
	
	for _, comp in ipairs(components) do
		traverseAndProfile(comp.RootNode, profiles)
	end
	
	local constantMap = {}
	local declarations = {}
	local nameCounters = {}
	
	for formatted, profile in pairs(profiles) do
		local complexity = calculateComplexity(profile.Type, profile.Value)
		local score = complexity * profile.Frequency
		
		-- Heuristic threshold: score >= 6 and frequency > 1
		if score >= 6 and profile.Frequency > 1 then
			local bestProp = ""
			local maxP = 0
			for p, c in pairs(profile.Props) do
				if c > maxP then
					maxP = c
					bestProp = p
				end
			end
			
			local baseName = getSmartName(bestProp, profile.Type, profile.Value)
			nameCounters[baseName] = (nameCounters[baseName] or 0) + 1
			
			local varName = baseName
			if nameCounters[baseName] > 1 then
				varName = baseName .. "_" .. nameCounters[baseName]
			end
			
			constantMap[formatted] = varName
			table.insert(declarations, string.format("local %s = %s", varName, formatted))
		end
	end
	
	table.sort(declarations)
	
	for _, root in ipairs(roots) do
		traverseAndReplace(root, constantMap)
	end
	
	for _, comp in ipairs(components) do
		traverseAndReplace(comp.RootNode, constantMap)
	end
	
	return declarations
end

return ConstantExtractor
