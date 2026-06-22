local React = require(script.Parent.Parent.Library.Roact.React)
local StudioComponents = require(script.Parent.Parent.Library.studiocomponents)
local Highlighter = require(script.Parent.Parent.Library.Highlighter)
local usePlugin = require(script.Parent.Parent.Library.studiocomponents.Hooks.usePlugin)

local function CodeEditor(props)
	local theme = StudioComponents.useTheme()
	
	local code = props.Code or ""
	local displayCode = code
	if #displayCode > 150000 then
		displayCode = string.sub(displayCode, 1, 150000) .. "\n\n-- [WARNING: Code truncated for UI preview due to length limits. Use 'Export' to view full source.]"
	end
	
	local richTextLines = React.useMemo(function()
		return Highlighter.buildRichTextLines({ src = displayCode })
	end, {displayCode})
	
	local instanceName = props.InstanceName or "ScreenGui"
	local converterName = props.ConverterName or "Roact"
	local generationTimeMs = props.GenerationTimeMs or 0
	local plugin = usePlugin()
	
	local contentChildren = {
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
	}
	
	for i, richLine in ipairs(richTextLines) do
		contentChildren["Row_" .. i] = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			LayoutOrder = i,
		}, {
			LineNum = React.createElement("TextLabel", {
				Size = UDim2.new(0, 35, 1, 0),
				BackgroundTransparency = 1,
				Text = tostring(i),
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
				TextXAlignment = Enum.TextXAlignment.Right,
				Font = Enum.Font.Code,
				TextSize = 14,
			}),
			CodeText = React.createElement("TextLabel", {
				Size = UDim2.new(1, -55, 1, 0),
				Position = UDim2.new(0, 55, 0, 0),
				BackgroundTransparency = 1,
				Text = richLine,
				RichText = true,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.Code,
				TextSize = 14,
			})
		})
	end
	
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
		Scroll = React.createElement(StudioComponents.ScrollFrame, {
			Size = UDim2.new(1, 0, 1, -33),
			Position = UDim2.new(0, 0, 0, 33),
			CanvasSize = UDim2.new(2, 0, 0, #richTextLines * 16 + 10),
		}, {
			LineNumbersBG = React.createElement("Frame", {
				Size = UDim2.new(0, 45, 1, 0),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScrollBarBackground),
				BorderSizePixel = 0,
				ZIndex = 0,
			}),
			LineNumbersDivider = React.createElement("Frame", {
				Size = UDim2.new(0, 1, 1, 0),
				Position = UDim2.new(0, 45, 0, 0),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
				BorderSizePixel = 0,
				ZIndex = 0,
			}),
			Content = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				ZIndex = 1,
			}, contentChildren)
		})
	})
end

return CodeEditor
