local BehaviorAnalyzer = {}

function BehaviorAnalyzer.analyze(roots)
	local function traverse(node, parentNode)
		if node.Type == "Script" then
			if parentNode then
				BehaviorAnalyzer.extractBehaviors(node, parentNode)
			end
			return true -- indicate this is a script to be removed from children
		end
		
		local newChildren = {}
		if node.Children then
			for _, child in ipairs(node.Children) do
				local isScript = traverse(child, node)
				if not isScript then
					table.insert(newChildren, child)
				end
			end
		end
		node.Children = newChildren
		
		-- Parse Attributes
		if node.Attributes then
			for k, v in pairs(node.Attributes) do
				if k:sub(1, 6) == "State_" then
					node.States = node.States or {}
					node.States[k:sub(7)] = { Type = "Attribute", Initial = v, AffectedProperties = {} }
				elseif k:sub(1, 6) == "Param_" then
					node.Params = node.Params or {}
					node.Params[k:sub(7)] = v
				elseif k:sub(1, 6) == "Event_" then
					node.Events = node.Events or {}
					node.Events[k:sub(7)] = v
				end
			end
		end
		return false
	end
	
	for _, root in ipairs(roots) do
		traverse(root, nil)
	end
end

function BehaviorAnalyzer.extractBehaviors(scriptNode, targetNode)
	local source = scriptNode.Source
	if not source or source == "" then return end
	
	-- Chunked processing by lines
	local lines = source:split("\n")
	
	local hasHover = false
	local hasPress = false
	local hasClick = false
	
	local hoverProps = {}
	local pressProps = {}
	
	local currentScope = nil
	
	local animatable = {"BackgroundColor3", "Size", "Position", "Transparency", "ImageTransparency", "TextTransparency", "Rotation", "Color", "TextColor3", "ImageColor3"}
	
	local processedLines = 0
	for _, line in ipairs(lines) do
		processedLines = processedLines + 1
		if processedLines % 100 == 0 then task.wait() end
		
		if line:find("MouseEnter") or line:find("MouseLeave") then
			hasHover = true
			currentScope = hoverProps
		elseif line:find("MouseButton1Down") or line:find("MouseButton1Up") then
			hasPress = true
			currentScope = pressProps
		elseif line:find("Activated") or line:find("MouseButton1Click") then
			hasClick = true
		end
		
		if currentScope then
			for _, prop in ipairs(animatable) do
				if line:find(prop) then
					currentScope[prop] = true
				end
			end
		end
		
		-- If end of a function block, we might lose scope, but for simplicity we associate all found props
	end
	
	if hasHover then
		targetNode.States = targetNode.States or {}
		targetNode.States["isHovered"] = { Type = "Inferred", AffectedProperties = hoverProps }
	end
	
	if hasPress then
		targetNode.States = targetNode.States or {}
		targetNode.States["isPressed"] = { Type = "Inferred", AffectedProperties = pressProps }
	end
	
	if hasClick then
		targetNode.Events = targetNode.Events or {}
		targetNode.Events["OnClick"] = true
	end
end

return BehaviorAnalyzer
