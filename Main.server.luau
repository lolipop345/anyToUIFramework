local Images = require(script.Parent:WaitForChild("Images"))

-- Create the Toolbar
local toolbar = plugin:CreateToolbar("Codify")

-- Create the Button
local toolbarButton = toolbar:CreateButton(
	"Open Codify",
	"Convert UI elements to reactive code",
	Images.ToolbarIcon.Icon
)

-- Create DockWidgetPluginGui
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false, -- Initially hidden
	false, -- Don't override previous state
	400, 500, -- Default size
	300, 400 -- Minimum size
)

local pluginGui = plugin:CreateDockWidgetPluginGui("CodifyMainWidget", widgetInfo)
pluginGui.Title = "Codify - Reactive UI Converter"

-- Basic DockWidget UI Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromScale(1, 1)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = pluginGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Text = "Codify is Ready"
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Position = UDim2.new(0, 0, 0.5, -25)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 24
titleLabel.TextWrapped = true
titleLabel.Parent = mainFrame

-- Toggle logic
toolbarButton.Click:Connect(function()
	pluginGui.Enabled = not pluginGui.Enabled
end)

pluginGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	toolbarButton:SetActive(pluginGui.Enabled)
end)
