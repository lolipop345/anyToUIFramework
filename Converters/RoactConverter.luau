local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))
local DependencyHelper = require(script.Parent:WaitForChild("DependencyHelper"))
local IRBuilder = require(script.Parent:WaitForChild("IRBuilder"))
local ComponentExtractor = require(script.Parent:WaitForChild("ComponentExtractor"))
local ConstantExtractor = require(script.Parent:WaitForChild("ConstantExtractor"))
local BehaviorAnalyzer = require(script.Parent:WaitForChild("BehaviorAnalyzer"))

local RoactConverter = {}

local function generateRoactCode(node, indentLevel, parentChildNames)
	local indent = string.rep("\t", indentLevel)
	local nextIndent = string.rep("\t", indentLevel + 1)
	
	if node.Type == "ComponentCall" then
		local args = {}
		for pName, pVal in pairs(node.Props) do
			table.insert(args, string.format('%s%s = %s,', nextIndent, pName, PropertyHelper.formatValue(pVal)))
		end
		
		if node.Events and node.Events.OnClick then
			table.insert(args, string.format('%s[Roact.Event.Activated] = props.OnClick,', nextIndent))
		end
		
		if #args > 0 then
			return string.format('%sRoact.createElement(%s, {\n%s\n%s})', indent, node.ComponentName, table.concat(args, "\n"), indent)
		else
			return string.format('%sRoact.createElement(%s, {})', indent, node.ComponentName)
		end
	end
	
	local code = {}
	table.insert(code, string.format('%sRoact.createElement(%q, {', indent, node.ClassName))
	
	local propsAdded = 0
	for propName, val in pairs(node.Properties) do
		local isAffectedByHover = node.States and node.States.isHovered and node.States.isHovered.AffectedProperties[propName]
		local isAffectedByPress = node.States and node.States.isPressed and node.States.isPressed.AffectedProperties[propName]
		
		if isAffectedByPress then
			table.insert(code, string.format('%s%s = isPressed and props.Pressed_%s or %s,', nextIndent, propName, propName, PropertyHelper.formatValue(val)))
		elseif isAffectedByHover then
			table.insert(code, string.format('%s%s = isHovered and props.Hover_%s or %s,', nextIndent, propName, propName, PropertyHelper.formatValue(val)))
		else
			table.insert(code, string.format('%s%s = %s,', nextIndent, propName, PropertyHelper.formatValue(val)))
		end
		propsAdded = propsAdded + 1
	end
	
	for propName, paramName in pairs(node.ParamBindings or {}) do
		local isAffectedByHover = node.States and node.States.isHovered and node.States.isHovered.AffectedProperties[propName]
		if isAffectedByHover then
			table.insert(code, string.format('%s%s = isHovered and props.Hover_%s or props.%s,', nextIndent, propName, paramName, paramName))
		else
			table.insert(code, string.format('%s%s = props.%s,', nextIndent, propName, paramName))
		end
		propsAdded = propsAdded + 1
	end
	
	if node.States and node.States.isHovered then
		table.insert(code, string.format('%s[Roact.Event.MouseEnter] = function() setIsHovered(true) end,', nextIndent))
		table.insert(code, string.format('%s[Roact.Event.MouseLeave] = function() setIsHovered(false) end,', nextIndent))
		propsAdded = propsAdded + 1
	end
	
	if node.States and node.States.isPressed then
		table.insert(code, string.format('%s[Roact.Event.InputBegan] = function(rbx, input) if input.UserInputType == Enum.UserInputType.MouseButton1 then setIsPressed(true) end end,', nextIndent))
		table.insert(code, string.format('%s[Roact.Event.InputEnded] = function(rbx, input) if input.UserInputType == Enum.UserInputType.MouseButton1 then setIsPressed(false) end end,', nextIndent))
		propsAdded = propsAdded + 1
	end
	
	if node.Events and node.Events.OnClick then
		table.insert(code, string.format('%s[Roact.Event.Activated] = props.OnClick or function() end,', nextIndent))
		propsAdded = propsAdded + 1
	end
	
	local children = node.Children
	if #children > 0 then
		table.insert(code, string.format('%s}, {', indent))
		
		local childNames = {}
		for _, child in ipairs(children) do
			local baseName = child.Name
			local uniqueName = baseName
			local suffix = 1
			while childNames[uniqueName] do
				uniqueName = baseName .. tostring(suffix)
				suffix = suffix + 1
			end
			childNames[uniqueName] = true
			
			local childCode = generateRoactCode(child, indentLevel + 1, childNames)
			
			local firstLineBreak = childCode:find("\n")
			if firstLineBreak then
				local firstLine = childCode:sub(1, firstLineBreak - 1)
				local rest = childCode:sub(firstLineBreak)
				local trimmedFirst = firstLine:match("^%s*(.-)$")
				table.insert(code, string.format('%s[%q] = %s%s,', nextIndent, uniqueName, trimmedFirst, rest))
			else
				local trimmed = childCode:match("^%s*(.-)$")
				table.insert(code, string.format('%s[%q] = %s,', nextIndent, uniqueName, trimmed))
			end
		end
		
		table.insert(code, string.format('%s})', indent))
	else
		table.insert(code, string.format('%s})', indent))
	end
	
	return table.concat(code, "\n")
end

function RoactConverter.Convert(instances)
	if typeof(instances) ~= "table" then
		instances = {instances}
	end
	
	local rootNodes = {}
	for _, inst in ipairs(instances) do
		local node = IRBuilder.build(inst)
		if node then
			table.insert(rootNodes, node)
		end
	end
	
	BehaviorAnalyzer.analyze(rootNodes)
	
	local newRoots, components = ComponentExtractor.extract(rootNodes)
	local declarations = ConstantExtractor.extract(newRoots, components)
	
	local results = {}
	table.insert(results, DependencyHelper.resolve("Roact"))
	table.insert(results, "")
	
	if #declarations > 0 then
		for _, decl in ipairs(declarations) do
			table.insert(results, decl)
		end
		table.insert(results, "")
	end
	
	for _, comp in ipairs(components) do
		table.insert(results, string.format("local function %s(props)", comp.Name))
		
		if comp.RootNode.States and comp.RootNode.States.isHovered then
			table.insert(results, "\tlocal isHovered, setIsHovered = Roact.createBinding(false)")
			table.insert(results, "\tlocal function setIsHoveredTrue() setIsHovered(true) end")
			table.insert(results, "\tlocal function setIsHoveredFalse() setIsHovered(false) end")
		end
		
		local compCode = generateRoactCode(comp.RootNode, 1, {})
		table.insert(results, string.format("\treturn %s", compCode:match("^%s*(.-)$")))
		table.insert(results, "end")
		table.insert(results, "")
	end
	
	table.insert(results, "return function()")
	
	local rootCodes = {}
	for _, node in ipairs(newRoots) do
		table.insert(rootCodes, generateRoactCode(node, 1, {}):sub(2))
	end
	
	if #rootCodes == 1 then
		table.insert(results, "\treturn " .. rootCodes[1])
	else
		table.insert(results, "\treturn Roact.createFragment({")
		for i, code in ipairs(rootCodes) do
			local key = newRoots[i].Name or ("Item" .. tostring(i))
			table.insert(results, string.format("\t\t[%q] = %s,", key, code))
		end
		table.insert(results, "\t})")
	end
	
	table.insert(results, "end")
	return table.concat(results, "\n")
end

return RoactConverter
