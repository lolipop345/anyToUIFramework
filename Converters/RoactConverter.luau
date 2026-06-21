local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))

local RoactConverter = {}

local function generateRoactCode(instance, indentLevel, parentChildNames)
	local indent = string.rep("\t", indentLevel)
	local nextIndent = string.rep("\t", indentLevel + 1)
	
	local code = {}
	table.insert(code, string.format('%sRoact.createElement(%q, {', indent, instance.ClassName))
	
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
	
	local results = {}
	table.insert(results, "local Roact = require(game.ReplicatedStorage.Roact)")
	table.insert(results, "")
	table.insert(results, "return function()")
	
	local rootCodes = {}
	for _, instance in ipairs(instances) do
		table.insert(rootCodes, generateRoactCode(instance, 1, {}):sub(2))
	end
	
	table.insert(results, "\treturn " .. table.concat(rootCodes, ",\n\t\t"))
	
	table.insert(results, "end")
	return table.concat(results, "\n")
end

return RoactConverter
