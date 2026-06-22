local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))

local IRBuilder = {}

local function generateStructureHash(node)
	local parts = {node.ClassName}
	if node.Children then
		for _, child in ipairs(node.Children or {}) do
			table.insert(parts, generateStructureHash(child))
		end
	end
	return table.concat(parts, "|")
end

local processedCount = 0

function IRBuilder.build(instance)
	processedCount = processedCount + 1
	if processedCount % 50 == 0 then
		task.wait()
	end
	
	if instance:IsA("LuaSourceContainer") then
		local source = ""
		pcall(function() source = instance.Source end)
		return {
			Type = "Script",
			Name = instance.Name,
			ClassName = instance.ClassName,
			Source = source,
			Hash = "Script",
			Properties = {},
			Children = {},
			Attributes = {}
		}
	end
	
	local node = {
		Type = "Instance",
		Name = instance.Name,
		ClassName = instance.ClassName,
		Properties = {},
		Children = {},
		Attributes = {},
		SourceInstance = instance
	}
	
	pcall(function()
		node.Attributes = instance:GetAttributes()
	end)
	
	local properties = PropertyHelper.getProperties(instance.ClassName) or {}
	for _, propName in ipairs(properties) do
		local success, val = pcall(function() return instance[propName] end)
		if success and val ~= nil then
			local defaultVal = PropertyHelper.getDefault(instance.ClassName, propName)
			if val ~= defaultVal or propName == "Name" then
				node.Properties[propName] = val
			end
		end
	end
	
	for _, child in ipairs(instance:GetChildren() or {}) do
		local childNode = IRBuilder.build(child)
		if childNode then
			table.insert(node.Children, childNode)
		end
	end
	
	node.Hash = generateStructureHash(node)
	return node
end

function IRBuilder.resetCounter()
	processedCount = 0
end

return IRBuilder
