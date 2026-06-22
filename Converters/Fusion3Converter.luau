local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))
local DependencyHelper = require(script.Parent:WaitForChild("DependencyHelper"))
local IRBuilder = require(script.Parent:WaitForChild("IRBuilder"))
local ComponentExtractor = require(script.Parent:WaitForChild("ComponentExtractor"))

local Fusion3Converter = {}

local function generateFusion3Code(node, indentLevel)
	local indent = string.rep("\t", indentLevel)
	local nextIndent = string.rep("\t", indentLevel + 1)
	
	if node.Type == "ComponentCall" then
		local args = {}
		for pName, pVal in pairs(node.Props) do
			table.insert(args, string.format('%s = %s', pName, PropertyHelper.formatValue(pVal)))
		end
		if #args > 0 then
			return string.format('%s%s(scope, {\n%s%s\n%s})', indent, node.ComponentName, nextIndent, table.concat(args, ",\n" .. nextIndent), indent)
		else
			return string.format('%s%s(scope, {})', indent, node.ComponentName)
		end
	end
	
	local code = {}
	table.insert(code, string.format('%sscope:New %q {', indent, node.ClassName))
	
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
		if propsAdded > 0 then
			table.insert(code, "")
		end
		
		for i, child in ipairs(children) do
			local childCode = generateFusion3Code(child, indentLevel + 1)
			table.insert(code, childCode .. ",")
		end
	end
	
	table.insert(code, string.format('%s}', indent))
	return table.concat(code, "\n")
end

function Fusion3Converter.Convert(instances)
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
	table.insert(results, DependencyHelper.resolve("Fusion"))
	table.insert(results, "")
	
	for _, comp in ipairs(components) do
		table.insert(results, string.format("local function %s(scope, props)", comp.Name))
		local compCode = generateFusion3Code(comp.RootNode, 1)
		table.insert(results, string.format("\treturn %s", compCode:match("^%s*(.-)$")))
		table.insert(results, "end")
		table.insert(results, "")
	end
	
	table.insert(results, "return function(scope)")
	
	local rootCodes = {}
	for _, node in ipairs(newRoots) do
		table.insert(rootCodes, generateFusion3Code(node, 1):sub(2))
	end
	
	table.insert(results, "\treturn " .. table.concat(rootCodes, ",\n\t\t"))
	table.insert(results, "end")
	return table.concat(results, "\n")
end

return Fusion3Converter
