local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))

local IRBuilder = {}

local function generateStructureHash(node)
	if type(node) ~= "table" then return "" end
	local parts = {tostring(node.ClassName)}
	local children = node.Children
	if type(children) == "table" then
		for i = 1, #children do
			local child = children[i]
			if child then
				table.insert(parts, generateStructureHash(child))
			end
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
	
	local properties = PropertyHelper.getProperties(instance.ClassName)
	if type(properties) == "table" then
		for i = 1, #properties do
			local propName = properties[i]
			local success, val = pcall(function() return instance[propName] end)
			if success and val ~= nil then
				local defaultVal = PropertyHelper.getDefault(instance.ClassName, propName)
				if val ~= defaultVal or propName == "Name" then
					node.Properties[propName] = val
				end
			end
		end
	end
	
	local instChildren = instance:GetChildren()
	if type(instChildren) == "table" then
		for i = 1, #instChildren do
			local childNode = IRBuilder.build(instChildren[i])
			if childNode then
				table.insert(node.Children, childNode)
			end
		end
	end
	
	node.Hash = generateStructureHash(node)
	return node
end

function IRBuilder.resetCounter()
	processedCount = 0
end

return IRBuilder
