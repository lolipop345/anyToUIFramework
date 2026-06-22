local DependencyHelper = {}

function DependencyHelper.resolve(moduleName)
	local targetModule = nil
	local servicesToSearch = {"ReplicatedStorage", "ServerScriptService", "ReplicatedFirst", "StarterPlayer"}
	
	for _, serviceName in ipairs(servicesToSearch) do
		local success, service = pcall(function() return game:GetService(serviceName) end)
		if success and service then
			for _, desc in ipairs(service:GetDescendants()) do
				if desc:IsA("ModuleScript") and desc.Name:lower() == moduleName:lower() then
					targetModule = desc
					break
				end
			end
		end
		if targetModule then break end
	end
	
	if not targetModule then
		return string.format('local %s = require(game:GetService("ReplicatedStorage"):WaitForChild(%q))', moduleName, moduleName)
	end
	
	local path = {}
	local current = targetModule
	while current and current ~= game do
		table.insert(path, 1, current)
		current = current.Parent
	end
	
	local reqCode = {}
	table.insert(reqCode, string.format('local %s = game:GetService(%q)', path[1].Name, path[1].ClassName))
	
	local prevVar = path[1].Name
	for i = 2, #path - 1 do
		local node = path[i]
		local varName = node.Name:gsub("%W", "")
		if varName == "" or varName:match("^%d") then varName = "Node" .. varName end
		table.insert(reqCode, string.format('local %s = %s:WaitForChild(%q, 5)', varName, prevVar, node.Name))
		prevVar = varName
	end
	
	local targetNode = path[#path]
	table.insert(reqCode, string.format('local %s = require(%s:WaitForChild(%q, 5))', moduleName, prevVar, targetNode.Name))
	
	return table.concat(reqCode, "\n")
end

return DependencyHelper
