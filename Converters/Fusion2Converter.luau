local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))
local DependencyHelper = require(script.Parent:WaitForChild("DependencyHelper"))
local IRBuilder = require(script.Parent:WaitForChild("IRBuilder"))
local ComponentExtractor = require(script.Parent:WaitForChild("ComponentExtractor"))
local ConstantExtractor = require(script.Parent:WaitForChild("ConstantExtractor"))

local Fusion2Converter = {}

local function generateFusion2Code(node, indentLevel)
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
	table.insert(code, string.format('%sNew %q {', indent, node.ClassName))
	
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
		table.insert(code, string.format('%s[Children] = {', nextIndent))
		
		for i, child in ipairs(children) do
			local childCode = generateFusion2Code(child, indentLevel + 2)
			table.insert(code, childCode .. ",")
		end
		
		table.insert(code, string.format('%s}', nextIndent))
	end
	
	table.insert(code, string.format('%s}', indent))
	return table.concat(code, "\n")
end

function Fusion2Converter.Convert(instances)
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
	local declarations = ConstantExtractor.extract(newRoots, components)
	
	local results = {}
	table.insert(results, DependencyHelper.resolve("Fusion"))
	table.insert(results, "local New = Fusion.New")
	table.insert(results, "local Children = Fusion.Children")
	table.insert(results, "")
	
	if #declarations > 0 then
		for _, decl in ipairs(declarations) do
			table.insert(results, decl)
		end
		table.insert(results, "")
	end
	
	for _, comp in ipairs(components) do
		table.insert(results, string.format("local function %s(props)", comp.Name))
		local compCode = generateFusion2Code(comp.RootNode, 1)
		table.insert(results, string.format("\treturn %s", compCode:match("^%s*(.-)$")))
		table.insert(results, "end")
		table.insert(results, "")
	end
	
	table.insert(results, "return function()")
	
	local rootCodes = {}
	for _, node in ipairs(newRoots) do
		table.insert(rootCodes, generateFusion2Code(node, 1):sub(2))
	end
	
	if #rootCodes == 1 then
		table.insert(results, "\treturn " .. rootCodes[1])
	else
		table.insert(results, "\treturn {")
		for _, code in ipairs(rootCodes) do
			table.insert(results, string.format("\t\t%s,", code))
		end
		table.insert(results, "\t}")
	end
	
	table.insert(results, "end")
	return table.concat(results, "\n")
end

return Fusion2Converter
