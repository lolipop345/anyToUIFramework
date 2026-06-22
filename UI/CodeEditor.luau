local React = require(script.Parent.Parent.Library.Roact.React)
local StudioComponents = require(script.Parent.Parent.Library.studiocomponents)
local Highlighter = require(script.Parent.Parent.Library.Highlighter)

local function CodeEditor(props)
	local textRef = React.useRef(nil)
	local theme = StudioComponents.useTheme()
	
	local code = props.Code or ""
	local instanceName = props.InstanceName or "ScreenGui"
	local converterName = props.ConverterName or "Roact"
	
	React.useEffect(function()
		local cleanup
		if textRef.current then
			cleanup = Highlighter.highlight({
				textObject = textRef.current,
				src = code,
				forceUpdate = true
			})
		end
		
		return function()
			if cleanup then
				cleanup()
			end
		end
	end, {code})

	local lines = string.split(code, "\n")
	local lineNumbers = ""
	for i = 1, #lines do
		lineNumbers = lineNumbers .. tostring(i) .. " |\n"
	end
	
	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		BorderSizePixel = 1,
	}, {
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
				Text = string.format("%s_%s.luau", instanceName, converterName),
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.TitlebarText),
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.Code,
				TextSize = 14,
			}),
			CopyButton = React.createElement(StudioComponents.Button, {
				Size = UDim2.new(0, 80, 0, 24),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Text = "Copy Code",
				OnActivated = function()
					if props.OnCopy then
						props.OnCopy(code)
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
			LineNumbers = React.createElement("TextLabel", {
				Size = UDim2.new(0, 40, 1, 0),
				BackgroundTransparency = 1,
				Text = lineNumbers,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Top,
				Font = Enum.Font.Code,
				TextSize = 14,
			}),
			CodeText = React.createElement("TextLabel", {
				Size = UDim2.new(1, -50, 1, 0),
				Position = UDim2.new(0, 50, 0, 0),
				BackgroundTransparency = 1,
				Text = "",
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Font = Enum.Font.Code,
				TextSize = 14,
				ref = textRef,
			})
		})
	})
end

return CodeEditor
