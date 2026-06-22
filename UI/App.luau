local React = require(script.Parent.Parent.Library.Roact.React)
local StudioComponents = require(script.Parent.Parent.Library.studiocomponents)
local CodeEditor = require(script.Parent.CodeEditor)
local Converters = require(script.Parent.Parent.Converters)

local Selection = game:GetService("Selection")
local StudioService = game:GetService("StudioService")

local function App(props)
	local selectedConverter, setSelectedConverter = React.useState("Roact")
	local generatedCode, setGeneratedCode = React.useState("-- Select UI instances in Explorer to generate code.\n-- Example output will appear here.")
	local instanceName, setInstanceName = React.useState("SelectedInstances")
	local generationTimeMs, setGenerationTimeMs = React.useState(0)
	
	React.useEffect(function()
		local function updateCode()
			local selected = Selection:Get()
			if #selected > 0 then
				setInstanceName(selected[1].Name)
				local converter = Converters[selectedConverter]
				if converter and converter.Convert then
					local startTime = os.clock()
					local success, code = pcall(function()
						return converter.Convert(selected)
					end)
					local endTime = os.clock()
					setGenerationTimeMs(math.floor((endTime - startTime) * 1000))
					
					if success then
						setGeneratedCode(code)
					else
						setGeneratedCode("-- Error generating code: " .. tostring(code))
					end
				end
			else
				setGeneratedCode("-- Select UI instances in Explorer to generate code.")
			end
		end
		
		updateCode()
		local connection = Selection.SelectionChanged:Connect(updateCode)
		return function()
			connection:Disconnect()
		end
	end, {selectedConverter})
	
	local function copyToClipboard(text)
		StudioService:CopyToClipboard(text)
	end
	
	local convertersList = {"React", "Roact", "Fusion2", "Fusion3", "Vide", "Legacy"}
	
	return React.createElement(StudioComponents.Background, {
		Size = UDim2.fromScale(1, 1),
	}, {
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 10),
		}),
		
		-- Toolbar Section (Submenu)
		Toolbar = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			ZIndex = 2,
		}, {
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 10),
			}),
			Label = React.createElement(StudioComponents.Label, {
				Text = "Target Framework:",
				Size = UDim2.new(0, 110, 1, 0),
				LayoutOrder = 1,
			}),
			Dropdown = React.createElement(StudioComponents.Dropdown, {
				Items = convertersList,
				SelectedItem = selectedConverter,
				OnItemSelected = function(item)
					if item then setSelectedConverter(item) end
				end,
				Size = UDim2.new(0, 150, 0, 28),
				LayoutOrder = 2,
			}),
		}),
		
		-- Code Editor Section
		EditorWrapper = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, -42),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			ZIndex = 1,
		}, {
			CodeEditor = React.createElement(CodeEditor, {
				Code = generatedCode,
				InstanceName = instanceName,
				ConverterName = selectedConverter,
				GenerationTimeMs = generationTimeMs,
				OnCopy = copyToClipboard
			})
		})
	})
end

return App
