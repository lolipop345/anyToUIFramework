local PropertyHelper = require(script.Parent:WaitForChild("PropertyHelper"))

local IRBuilder = {}

local function generateStructureHash(node)
	local parts = {node.ClassName}
	for _, child in ipairs(node.Children) do
		table.insert(parts, generateStructureHash(child))
	end
	return table.concat(parts, "|")
end

function IRBuilder.build(instance)
	if instance:IsA("LuaSourceContainer") then
		return nil
	end
	
	local node = {
		Type = "Instance",
		Name = instance.Name,
		ClassName = instance.ClassName,
		Properties = {},
		Children = {},
		SourceInstance = instance
	}
	
	local properties = PropertyHelper.getProperties(instance.ClassName)
	for _, propName in ipairs(properties) do
		local success, val = pcall(function() return instance[propName] end)
		if success and val ~= nil then
			local defaultVal = PropertyHelper.getDefault(instance.ClassName, propName)
			if val ~= defaultVal or propName == "Name" then
				node.Properties[propName] = val
			end
		end
	end
	
	for _, child in ipairs(instance:GetChildren()) do
		local childNode = IRBuilder.build(child)
		if childNode then
			table.insert(node.Children, childNode)
		end
	end
	
	node.Hash = generateStructureHash(node)
	return node
end

return IRBuilder
