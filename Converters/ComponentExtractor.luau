local ComponentExtractor = {}

local function getBaseName(name)
	local base = name:match("^(.-)%d*$")
	if not base or base == "" then return name end
	-- Capitalize the first letter for proper component naming
	base = base:sub(1, 1):upper() .. base:sub(2)
	return base
end

local function traverseDeepCollect(nodes, currentPath, diffs, baseProps)
	local firstNode = nodes[1]
	
	-- Compare properties
	local propsFound = {}
	for _, node in ipairs(nodes) do
		for propName, val in pairs(node.Properties) do
			if propName == "Name" then continue end
			propsFound[propName] = true
		end
	end
	
	for propName, _ in pairs(propsFound) do
		local allSame = true
		local firstVal = firstNode.Properties[propName]
		for i = 2, #nodes do
			if nodes[i].Properties[propName] ~= firstVal then
				allSame = false
				break
			end
		end
		
		if allSame then
			-- Save to base props
			table.insert(baseProps, {
				Path = currentPath,
				Property = propName,
				Value = firstVal
			})
		else
			-- Mark as diff (parameter)
			local paramName = (currentPath == "" and propName) or (currentPath .. "_" .. propName)
			table.insert(diffs, {
				Path = currentPath,
				Property = propName,
				ParamName = paramName
			})
		end
	end
	
	-- Recurse children
	for childIdx, firstChild in ipairs(firstNode.Children) do
		local childNodes = {}
		for _, node in ipairs(nodes) do
			table.insert(childNodes, node.Children[childIdx])
		end
		local nextPath = (currentPath == "" and firstChild.Name) or (currentPath .. "_" .. firstChild.Name)
		traverseDeepCollect(childNodes, nextPath, diffs, baseProps)
	end
end

-- Rebuilds the component definition node structure with parameters
local function buildComponentTemplate(firstNode, diffs, currentPath)
	local template = {
		Type = "Instance",
		ClassName = firstNode.ClassName,
		Name = firstNode.Name,
		Properties = {},
		Children = {},
		ParamBindings = {},
		States = firstNode.States,
		Events = firstNode.Events,
		Attributes = firstNode.Attributes
	}
	
	for propName, val in pairs(firstNode.Properties) do
		if propName ~= "Name" then
			template.Properties[propName] = val
		end
	end
	
	for _, diff in ipairs(diffs) do
		if diff.Path == currentPath then
			template.Properties[diff.Property] = nil -- remove static value
			template.ParamBindings[diff.Property] = diff.ParamName
		end
	end
	
	for childIdx, childNode in ipairs(firstNode.Children) do
		local nextPath = (currentPath == "" and childNode.Name) or (currentPath .. "_" .. childNode.Name)
		local childTemplate = buildComponentTemplate(childNode, diffs, nextPath)
		table.insert(template.Children, childTemplate)
	end
	
	return template
end

function ComponentExtractor.extract(rootNodes)
	local structureGroups = {}
	
	local function collectCandidates(node)
		local hash = node.Hash
		if not structureGroups[hash] then
			structureGroups[hash] = {}
		end
		table.insert(structureGroups[hash], node)
		
		if node.Children then
			for _, child in ipairs(node.Children) do
				collectCandidates(child)
			end
		end
	end
	
	for _, node in ipairs(rootNodes) do
		collectCandidates(node)
	end
	
	local components = {}
	local replacedNodes = {} -- To prevent nested replacement issues in a single pass
	
	-- We want to group by BaseName as well inside the hash
	for hash, nodes in pairs(structureGroups) do
		local baseNameGroups = {}
		for _, node in ipairs(nodes) do
			local base = getBaseName(node.Name)
			if not baseNameGroups[base] then baseNameGroups[base] = {} end
			table.insert(baseNameGroups[base], node)
		end
		
		for baseName, groupNodes in pairs(baseNameGroups) do
			if #groupNodes >= 2 then
				local diffs = {}
				local baseProps = {}
				
				-- Deep compare
				traverseDeepCollect(groupNodes, "", diffs, baseProps)
				
				-- Create Component Template
				local compName = baseName
				local templateRoot = buildComponentTemplate(groupNodes[1], diffs, "")
				
				local paramsList = {}
				for _, diff in ipairs(diffs) do
					table.insert(paramsList, diff.ParamName)
				end
				
				table.insert(components, {
					Name = compName,
					Parameters = paramsList,
					RootNode = templateRoot
				})
				
				-- Mark nodes to be replaced
				for _, node in ipairs(groupNodes) do
					local args = {}
					for _, diff in ipairs(diffs) do
						-- Evaluate the node's property at that path
						local target = node
						if diff.Path ~= "" then
							local pathParts = string.split(diff.Path, "_")
							for _, p in ipairs(pathParts) do
								for _, c in ipairs(target.Children) do
									if c.Name == p then
										target = c
										break
									end
								end
							end
						end
						args[diff.ParamName] = target.Properties[diff.Property]
					end
					
					replacedNodes[node] = {
						Type = "ComponentCall",
						ComponentName = compName,
						Name = node.Name,
						Props = args,
						States = node.States,
						Events = node.Events
					}
				end
			end
		end
	end
	
	-- Rebuild the tree replacing nodes with ComponentCalls
	local function rebuildTree(node)
		if replacedNodes[node] then
			return replacedNodes[node]
		end
		
		local newNode = {
			Type = "Instance",
			ClassName = node.ClassName,
			Name = node.Name,
			Properties = node.Properties,
			Children = {}
		}
		
		for _, child in ipairs(node.Children) do
			local childNode = rebuildTree(child)
			if childNode then
				table.insert(newNode.Children, childNode)
			end
		end
		
		return newNode
	end
	
	local newRoots = {}
	for _, root in ipairs(rootNodes) do
		table.insert(newRoots, rebuildTree(root))
	end
	
	return newRoots, components
end

return ComponentExtractor
