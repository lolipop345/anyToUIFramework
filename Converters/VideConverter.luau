local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))

local VideConverter = {}

local function generateVideCode(instance, indentLevel)
	local indent = string.rep("\t", indentLevel)
	local nextIndent = string.rep("\t", indentLevel + 1)
	
	local code = {}
	table.insert(code, string.format('%svide.create %q {', indent, instance.ClassName))
	
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
		
		for i, child in ipairs(children) do
			local childCode = generateVideCode(child, indentLevel + 1)
			table.insert(code, childCode .. ",")
		end
	end
	
	table.insert(code, string.format('%s}', indent))
	return table.concat(code, "\n")
end

function VideConverter.Convert(instances)
	if typeof(instances) ~= "table" then
		instances = {instances}
	end
	
	local results = {}
	table.insert(results, "local vide = require(game.ReplicatedStorage.vide)")
	table.insert(results, "")
	table.insert(results, "return function()")
	
	for _, instance in ipairs(instances) do
		table.insert(results, generateVideCode(instance, 1))
	end
	
	table.insert(results, "end")
	return table.concat(results, "\n")
end

return VideConverter
