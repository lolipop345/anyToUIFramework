local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))
local DependencyHelper = require(script.Parent:WaitForChild("DependencyHelper"))
local IRBuilder = require(script.Parent:WaitForChild("IRBuilder"))
local ComponentExtractor = require(script.Parent:WaitForChild("ComponentExtractor"))

local ReactConverter = {}

local function generateReactCode(node, indentLevel, parentChildNames)
	local indent = string.rep("\t", indentLevel)
	local nextIndent = string.rep("\t", indentLevel + 1)
	
	if node.Type == "ComponentCall" then
		local args = {}
		for pName, pVal in pairs(node.Props) do
			table.insert(args, string.format('%s = %s', pName, PropertyHelper.formatValue(pVal)))
		end
		if #args > 0 then
			return string.format('%s%s({\n%s%s\n%s})', indent, node.ComponentName, nextIndent, table.concat(args, ",\n" .. nextIndent), indent)
		else
			return string.format('%s%s({})', indent, node.ComponentName)
		end
	end
	
	local code = {}
	table.insert(code, string.format('%sReact.createElement(%q, {', indent, node.ClassName))
	
	local propsAdded = 0
	for propName, val in pairs(node.Properties) do
		table.insert(code, string.format('%s%s = %s,', nextIndent, propName, PropertyHelper.formatValue(val)))
		propsAdded = propsAdded + 1
	end
	
	for propName, paramName in pairs(node.ParamBindings or {}) do
		table.insert(code, string.format('%s%s = props.%s,', nextIndent, propName, paramName))
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
			
			local childCode = generateReactCode(child, indentLevel + 1, childNames)
			
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

function ReactConverter.Convert(instances)
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
	
	local newRoots, components = ComponentExtractor.extract(rootNodes)
	
	local results = {}
	table.insert(results, DependencyHelper.resolve("React"))
	table.insert(results, "")
	
	for _, comp in ipairs(components) do
		table.insert(results, string.format("local function %s(props)", comp.Name))
		local compCode = generateReactCode(comp.RootNode, 1, {})
		table.insert(results, string.format("\treturn %s", compCode:match("^%s*(.-)$")))
		table.insert(results, "end")
		table.insert(results, "")
	end
	
	table.insert(results, "return function()")
	
	local rootCodes = {}
	for _, node in ipairs(newRoots) do
		table.insert(rootCodes, generateReactCode(node, 1, {}):sub(2))
	end
	
	if #rootCodes == 1 then
		table.insert(results, "\treturn " .. rootCodes[1])
	else
		table.insert(results, "\treturn React.createElement(React.Fragment, nil, {")
		for i, code in ipairs(rootCodes) do
			local key = newRoots[i].Name or ("Item" .. tostring(i))
			table.insert(results, string.format("\t\t[%q] = %s,", key, code))
		end
		table.insert(results, "\t})")
	end
	
	table.insert(results, "end")
	return table.concat(results, "\n")
end

return ReactConverter
