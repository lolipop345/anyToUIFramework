local React = require(script.Parent.Parent.Library.Roact.React)
local StudioComponents = require(script.Parent.Parent.Library.studiocomponents)
local Highlighter = require(script.Parent.Parent.Library.Highlighter)
local usePlugin = require(script.Parent.Parent.Library.studiocomponents.Hooks.usePlugin)

local function CodeEditor(props)
	local theme = StudioComponents.useTheme()
	local contentRef = React.useRef(nil)
	
	local code = props.Code or ""
	local displayCode = code
	if #displayCode > 150000 then
		displayCode = string.sub(displayCode, 1, 150000) .. "\n\n-- [WARNING: Code truncated for UI preview due to length limits. Use 'Export' to view full source.]"
	end
	
	local instanceName = props.InstanceName or "ScreenGui"
	local converterName = props.ConverterName or "Roact"
	local generationTimeMs = props.GenerationTimeMs or 0
	local plugin = usePlugin()
	
	React.useEffect(function()
		local contentFrame = contentRef.current
		if not contentFrame then return end
		
		-- Clear existing vanilla children
		for _, child in ipairs(contentFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name:match("^Row_") then
				child:Destroy()
			end
		end
		
		local richTextLines = Highlighter.buildRichTextLines({ src = displayCode })
		
		local cancelled = false
		local function renderLines()
			for i, richLine in ipairs(richTextLines) do
				if cancelled then return end
				
				local row = Instance.new("Frame")
				row.Name = "Row_" .. i
				row.Size = UDim2.new(1, 0, 0, 16)
				row.BackgroundTransparency = 1
				row.LayoutOrder = i
				
				local lineNum = Instance.new("TextLabel")
				lineNum.Name = "LineNum"
				lineNum.Size = UDim2.new(0, 35, 1, 0)
				lineNum.BackgroundTransparency = 1
				lineNum.Text = tostring(i)
				lineNum.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText)
				lineNum.TextXAlignment = Enum.TextXAlignment.Right
				lineNum.Font = Enum.Font.Code
				lineNum.TextSize = 14
				lineNum.Parent = row
				
				local codeText = Instance.new("TextLabel")
				codeText.Name = "CodeText"
				codeText.Size = UDim2.new(1, -55, 1, 0)
				codeText.Position = UDim2.new(0, 55, 0, 0)
				codeText.BackgroundTransparency = 1
				codeText.Text = richLine
				codeText.RichText = true
				codeText.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
				codeText.TextXAlignment = Enum.TextXAlignment.Left
				codeText.Font = Enum.Font.Code
				codeText.TextSize = 14
				codeText.Parent = row
				
				row.Parent = contentFrame
				
				-- Yield periodically to prevent blocking the main thread during massive generation
				if i % 150 == 0 then
					task.wait()
				end
			end
		end
		
		task.spawn(renderLines)
		
		return function()
			cancelled = true
		end
	end, {displayCode, theme})
	
	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		BorderSizePixel = 1,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Header = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
			BorderSizePixel = 0,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			Title = React.createElement("TextLabel", {
				Size = UDim2.new(1, -100, 1, 0),
				BackgroundTransparency = 1,
				Text = string.format("%s_%s.luau  •  %dms", instanceName, converterName, generationTimeMs),
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.TitlebarText),
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.Code,
				TextSize = 14,
			}),
			CopyButton = React.createElement(StudioComponents.Button, {
				Size = UDim2.new(0, 90, 0, 24),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Text = "Export",
				OnActivated = function()
					if plugin then
						local newScript = Instance.new("ModuleScript")
						newScript.Name = string.format("%s_%s", instanceName, converterName)
						newScript.Source = code
						newScript.Parent = game:GetService("ServerStorage")
						plugin:OpenScript(newScript)
					end
				end,
			})
		}),
		Divider = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0, 32),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			BorderSizePixel = 0,
		}),
		LineNumbersBG = React.createElement("Frame", {
			Size = UDim2.new(0, 45, 1, -33),
			Position = UDim2.new(0, 0, 0, 33),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScrollBarBackground),
			BorderSizePixel = 0,
			ZIndex = 0,
		}),
		LineNumbersDivider = React.createElement("Frame", {
			Size = UDim2.new(0, 1, 1, -33),
			Position = UDim2.new(0, 45, 0, 33),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			BorderSizePixel = 0,
			ZIndex = 0,
		}),
		Scroll = React.createElement(StudioComponents.ScrollFrame, {
			Size = UDim2.new(1, 0, 1, -33),
			Position = UDim2.new(0, 0, 0, 33),
			ZIndex = 1,
		}, {
			Content = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				ref = contentRef,
			}, {
				Padding = React.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5),
				}),
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Vertical,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
				})
			})
		})
	})
end

return CodeEditor
