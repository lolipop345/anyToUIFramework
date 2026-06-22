local React = require(script.Parent.Parent.Library.Roact.React)
local StudioComponents = require(script.Parent.Parent.Library.studiocomponents)
local Highlighter = require(script.Parent.Parent.Library.Highlighter)
local usePlugin = require(script.Parent.Parent.Library.studiocomponents.Hooks.usePlugin)

local function CodeEditor(props)
	local textRef = React.useRef(nil)
	local theme = StudioComponents.useTheme()
	
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
		local cleanup
		if textRef.current then
			cleanup = Highlighter.highlight({
				textObject = textRef.current,
				src = displayCode,
				forceUpdate = true
			})
		end
		
		return function()
			if cleanup then
				cleanup()
			end
		end
	end, {displayCode})

	local lines = string.split(displayCode, "\n")
	local lineNumbers = ""
	for i = 1, #lines do
		lineNumbers = lineNumbers .. tostring(i) .. "\n"
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
			CanvasSize = UDim2.new(2, 0, 0, math.max(400, #lines * 16 + 20)),
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 5),
				PaddingBottom = UDim.new(0, 5),
			}),
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
			LineNumbers = React.createElement("TextLabel", {
				Size = UDim2.new(0, 35, 1, 0),
				BackgroundTransparency = 1,
				Text = lineNumbers,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Top,
				Font = Enum.Font.Code,
				TextSize = 14,
				LineHeight = 1.2,
				ZIndex = 1,
			}),
			CodeText = React.createElement("TextLabel", {
				Size = UDim2.new(1, -55, 1, 0),
				Position = UDim2.new(0, 55, 0, 0),
				BackgroundTransparency = 1,
				Text = displayCode,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Font = Enum.Font.Code,
				TextSize = 14,
				LineHeight = 1.2,
				ZIndex = 1,
				ref = textRef,
			})
		})
	})
end

return CodeEditor
