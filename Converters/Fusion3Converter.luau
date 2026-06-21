local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))

local Fusion3Converter = {}

local function generateFusion3Code(instance, indentLevel)
	local indent = string.rep("\t", indentLevel)
	local nextIndent = string.rep("\t", indentLevel + 1)
	
	local code = {}
	table.insert(code, string.format('%sscope:New %q {', indent, instance.ClassName))
	
	local properties = PropertyHelper.getProperties(instance.ClassName)
	local propsAdded = 0
	
	for _, propName in ipairs(properties) do
		local success, val = pcall(function() return instance[propName] end)
		if success and val ~= nil then
			local defaultVal = PropertyHelper.getDefault(instance.ClassName, propName)
			if val ~= defaultVal or propName == "Name" then
				table.insert(code, string.format('%s%s = %s,', nextIndent, propName, PropertyHelper.formatValue(val)))
				propsAdded = propsAdded + 1
			end
		end
	end
	
	local children = instance:GetChildren()
	if #children > 0 then
		if propsAdded > 0 then
			table.insert(code, "")
		end
		table.insert(code, string.format('%s[Children] = {', nextIndent))
		
		for i, child in ipairs(children) do
			local childCode = generateFusion3Code(child, indentLevel + 2)
			table.insert(code, childCode .. ",")
		end
		
		table.insert(code, string.format('%s}', nextIndent))
	end
	
	table.insert(code, string.format('%s}', indent))
	return table.concat(code, "\n")
end

function Fusion3Converter.Convert(instances)
	if typeof(instances) ~= "table" then
		instances = {instances}
	end
	
	local results = {}
	table.insert(results, "local Fusion = require(game.ReplicatedStorage.Fusion)")
	table.insert(results, "local Children = Fusion.Children")
	table.insert(results, "")
	table.insert(results, "return function(scope)")
	
	local rootCodes = {}
	for _, instance in ipairs(instances) do
		table.insert(rootCodes, generateFusion3Code(instance, 1):sub(2))
	end
	
	table.insert(results, "\treturn " .. table.concat(rootCodes, ",\n\t\t"))
	
	table.insert(results, "end")
	return table.concat(results, "\n")
end

return Fusion3Converter
