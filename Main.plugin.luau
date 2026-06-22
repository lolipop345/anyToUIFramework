local RunService = game:GetService("RunService")
if RunService:IsRunMode() then
	return
end

local Images = require(script.Parent:WaitForChild("Images"))

-- Create the Toolbar
local toolbar = plugin:CreateToolbar("anyToUIFramework")

-- Create the Button
local toolbarButton = toolbar:CreateButton(
	"Open anyToUIFramework",
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

local pluginGui = plugin:CreateDockWidgetPluginGui("anyToUIFrameworkMainWidget", widgetInfo)
pluginGui.Title = "anyToUIFramework"

local React = require(script.Parent:WaitForChild("Library"):WaitForChild("Roact"):WaitForChild("React"))
local ReactRoblox = require(script.Parent:WaitForChild("Library"):WaitForChild("Roact"):WaitForChild("ReactRoblox"))
local StudioComponents = require(script.Parent:WaitForChild("Library"):WaitForChild("studiocomponents"))
local Highlighter = require(script.Parent:WaitForChild("Library"):WaitForChild("Highlighter"))

local App = require(script.Parent:WaitForChild("UI"):WaitForChild("App"))

-- Initialize Highlighter to adapt to Studio Theme changes
Highlighter.matchStudioSettings()

-- Basic DockWidget UI mounting
local root = ReactRoblox.createRoot(pluginGui)

local appElement = React.createElement(StudioComponents.PluginProvider, {
	Plugin = plugin,
}, {
	App = React.createElement(App, {
		plugin = plugin
	})
})

root:render(appElement)

-- Toggle logic
toolbarButton.Click:Connect(function()
	pluginGui.Enabled = not pluginGui.Enabled
end)

pluginGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	toolbarButton:SetActive(pluginGui.Enabled)
end)

