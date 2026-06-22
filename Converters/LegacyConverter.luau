local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))
local IRBuilder = require(script.Parent:WaitForChild("IRBuilder"))
local ComponentExtractor = require(script.Parent:WaitForChild("ComponentExtractor"))

local LegacyConverter = {}

local function generateLegacyCode(node, indentLevel, parentVarName, uniqueNames, allCode)
	local indent = string.rep("\t", indentLevel)
	
	if node.Type == "ComponentCall" then
		local baseName = node.Name:gsub("%W", "")
		if baseName == "" or baseName:match("^%d") then baseName = "Inst" .. baseName end
		local varName = baseName
		local suffix = 1
		while uniqueNames[varName] do
			varName = baseName .. tostring(suffix)
			suffix = suffix + 1
		end
		uniqueNames[varName] = true
		
		local args = {}
		for pName, pVal in pairs(node.Props) do
			table.insert(args, string.format('%s = %s', pName, PropertyHelper.formatValue(pVal)))
		end
		
		if #args > 0 then
			table.insert(allCode, string.format('%slocal %s = UIComponents.%s({\n\t%s%s\n%s})', indent, varName, node.ComponentName, indent, table.concat(args, ",\n\t" .. indent), indent))
		else
			table.insert(allCode, string.format('%slocal %s = UIComponents.%s({})', indent, varName, node.ComponentName))
		end
		
		if parentVarName then
			table.insert(allCode, string.format('%s%s.Parent = %s', indent, varName, parentVarName))
		end
		
		return varName
	end
	
	local baseName = node.Name:gsub("%W", "")
	if baseName == "" or baseName:match("^%d") then
		baseName = "Inst" .. baseName
	end
	
	local varName = baseName
	local suffix = 1
	while uniqueNames[varName] do
		varName = baseName .. tostring(suffix)
		suffix = suffix + 1
	end
	uniqueNames[varName] = true
	
	table.insert(allCode, string.format('%slocal %s = Instance.new(%q)', indent, varName, node.ClassName))
	
	for propName, val in pairs(node.Properties) do
		table.insert(allCode, string.format('%s%s.%s = %s', indent, varName, propName, PropertyHelper.formatValue(val)))
	end
	
	for propName, paramName in pairs(node.ParamBindings or {}) do
		table.insert(allCode, string.format('%s%s.%s = props.%s', indent, varName, propName, paramName))
	end
	
	if parentVarName then
		table.insert(allCode, string.format('%s%s.Parent = %s', indent, varName, parentVarName))
	end
	
	local children = node.Children
	if #children > 0 then
		table.insert(allCode, "")
		for _, child in ipairs(children) do
			generateLegacyCode(child, indentLevel, varName, uniqueNames, allCode)
		end
	end
	
	return varName
end

function LegacyConverter.Convert(instances)
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
	table.insert(results, "local UIComponents = {}")
	table.insert(results, "")
	
	for _, comp in ipairs(components) do
		table.insert(results, string.format("function UIComponents.%s(props)", comp.Name))
		local codeBlocks = {}
		local uniqueNames = {}
		local rootVar = generateLegacyCode(comp.RootNode, 1, nil, uniqueNames, codeBlocks)
		for _, line in ipairs(codeBlocks) do
			table.insert(results, line)
		end
		table.insert(results, "")
		table.insert(results, string.format("\treturn %s", rootVar))
		table.insert(results, "end")
		table.insert(results, "")
	end
	
	table.insert(results, "function UIComponents.CreateRoot()")
	local rootVars = {}
	local codeBlocks = {}
	local uniqueNames = {}
	for i, node in ipairs(newRoots) do
		local rootVar = generateLegacyCode(node, 1, nil, uniqueNames, codeBlocks)
		table.insert(rootVars, rootVar)
		if i < #newRoots then
			table.insert(codeBlocks, "")
		end
	end
	
	for _, line in ipairs(codeBlocks) do
		table.insert(results, line)
	end
	
	table.insert(results, "")
	if #rootVars == 1 then
		table.insert(results, "\treturn " .. rootVars[1])
	else
		table.insert(results, "\treturn " .. table.concat(rootVars, ", "))
	end
	
	table.insert(results, "end")
	table.insert(results, "")
	table.insert(results, "return UIComponents")
	return table.concat(results, "\n")
end

return LegacyConverter
