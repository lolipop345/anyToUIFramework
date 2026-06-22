local React = require(script.Parent.Parent.Library.Roact.React)
local StudioComponents = require(script.Parent.Parent.Library.studiocomponents)
local PreviewImages = require(script.Parent.Parent.Images.Preview)

local Selection = game:GetService("Selection")

local SIZES = {
	["480p"] = Vector2.new(854, 480),
	["720p"] = Vector2.new(1280, 720),
	["1080p"] = Vector2.new(1920, 1080),
	["1440p"] = Vector2.new(2560, 1440),
	["4K"] = Vector2.new(3840, 2160),
}

local function PreviewTab(props)
	local theme = StudioComponents.useTheme()
	
	local selectedSize, setSelectedSize = React.useState("1080p")
	local aspectRatio, setAspectRatio = React.useState("16:9")
	local uiScale, setUiScale = React.useState(0.5)
	local hasContent, setHasContent = React.useState(false)
	
	local containerRef = React.useRef(nil)
	
	-- Function to update the cloned instances in the preview
	React.useEffect(function()
		local function updatePreview()
			local container = containerRef.current
			if not container then return end
			
			-- Clear old preview
			for _, child in ipairs(container:GetChildren()) do
				if not child:IsA("UIScale") then
					child:Destroy()
				end
			end
			
			-- Clone selected items into the container
			local found = false
			local selected = Selection:Get()
			for _, inst in ipairs(selected) do
				if inst:IsA("GuiObject") then
					local clone = inst:Clone()
					clone.Parent = container
					found = true
				elseif inst:IsA("ScreenGui") or inst:IsA("Folder") then
					for _, child in ipairs(inst:GetChildren()) do
						if child:IsA("GuiObject") then
							local clone = child:Clone()
							clone.Parent = container
							found = true
						end
					end
				end
			end
			setHasContent(found)
		end
		
		updatePreview()
		local connection = Selection.SelectionChanged:Connect(updatePreview)
		
		return function()
			connection:Disconnect()
		end
	end, {})
	
	local sizeList = {"480p", "720p", "1080p", "1440p", "4K"}
	local ratioList = {"16:9", "16:10", "4:3", "9:16"}
	
	local currentRes = SIZES[selectedSize] or SIZES["1080p"]
	-- We apply aspect ratio math if needed, but standard sizes like 1080p imply 16:9.
	-- For simplicity, if they pick "9:16" on 1080p, we flip the dimensions.
	local x = currentRes.X
	local y = currentRes.Y
	if aspectRatio == "9:16" and x > y then
		x, y = y, x
	elseif aspectRatio == "4:3" then
		x = y * (4/3)
	elseif aspectRatio == "16:10" then
		x = y * (16/10)
	end
	
	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		
		-- Main Preview Area
		PreviewArea = React.createElement(StudioComponents.ScrollFrame, {
			Size = UDim2.new(1, -220, 1, 0),
			LayoutOrder = 1,
			Layout = {
				ClassName = "UIListLayout",
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}
		}, {
			-- A wrapper that correctly matches the SCALED size for the scroll frame's layout
			ScaleWrapper = React.createElement("Frame", {
				Size = UDim2.fromOffset(x * uiScale, y * uiScale),
				BackgroundTransparency = 1,
			}, {
				-- The "Screen" that gets scaled
				ScreenContainer = React.createElement("ImageLabel", {
					Size = UDim2.fromOffset(x, y),
					Position = UDim2.fromScale(0, 0),
					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Dark),
					Image = PreviewImages.CheckerTile,
					ImageTransparency = PreviewImages.TileTransparency,
					ScaleType = Enum.ScaleType.Tile,
					TileSize = PreviewImages.TileScale,
					ref = containerRef,
					ClipsDescendants = true,
				}, {
					Scale = React.createElement("UIScale", {
						Scale = uiScale,
					}),
					EmptyState = not hasContent and React.createElement(StudioComponents.Label, {
						Text = "Preview is empty\n\nSelect a UI element in the Explorer to view it here.",
						Size = UDim2.fromScale(1, 1),
						TextWrapped = true,
						Font = Enum.Font.SourceSansItalic,
						TextColorStyle = Enum.StudioStyleGuideColor.DimmedText,
					}),
				})
			})
		}),
		
		-- Settings Sidebar
		SettingsSidebar = React.createElement("Frame", {
			Size = UDim2.new(0, 220, 1, 0),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
			LayoutOrder = 2,
			BorderSizePixel = 0,
		}, {
			Border = React.createElement("Frame", {
				Size = UDim2.new(0, 1, 1, 0),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
				BorderSizePixel = 0,
				ZIndex = 2,
			}),
			ContentContainer = React.createElement("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 1,
			}, {
				Padding = React.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 15),
					PaddingLeft = UDim.new(0, 15),
					PaddingRight = UDim.new(0, 15),
				}),
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 15),
				}),
				
				Title = React.createElement(StudioComponents.Label, {
					Text = "Preview Settings",
					Font = Enum.Font.SourceSansBold,
					TextSize = 16,
					Size = UDim2.new(1, 0, 0, 20),
					LayoutOrder = 1,
				}),
				
				-- Aspect Ratio Dropdown
				RatioSection = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 45),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
				}, {
					Label = React.createElement(StudioComponents.Label, {
						Text = "Aspect Ratio",
						Size = UDim2.new(1, 0, 0, 15),
						Position = UDim2.fromOffset(0, 0),
					}),
					Dropdown = React.createElement(StudioComponents.Dropdown, {
						Items = ratioList,
						SelectedItem = aspectRatio,
						OnItemSelected = setAspectRatio,
						Size = UDim2.new(1, 0, 0, 25),
						Position = UDim2.fromOffset(0, 20),
					}),
				}),
				
				-- Size Dropdown
				SizeSection = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 45),
					BackgroundTransparency = 1,
					LayoutOrder = 3,
				}, {
					Label = React.createElement(StudioComponents.Label, {
						Text = "Screen Size",
						Size = UDim2.new(1, 0, 0, 15),
						Position = UDim2.fromOffset(0, 0),
					}),
					Dropdown = React.createElement(StudioComponents.Dropdown, {
						Items = sizeList,
						SelectedItem = selectedSize,
						OnItemSelected = setSelectedSize,
						Size = UDim2.new(1, 0, 0, 25),
						Position = UDim2.fromOffset(0, 20),
					}),
				}),
				
				-- UI Scale Input (Since standard studiocomponents might not have a slider)
				ScaleSection = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 45),
					BackgroundTransparency = 1,
					LayoutOrder = 4,
				}, {
					Label = React.createElement(StudioComponents.Label, {
						Text = string.format("UI Scale (%.2f)", uiScale),
						Size = UDim2.new(1, 0, 0, 15),
						Position = UDim2.fromOffset(0, 0),
					}),
					Input = React.createElement(StudioComponents.TextInput, {
						Text = tostring(uiScale),
						PlaceholderText = "e.g. 0.5",
						Size = UDim2.new(1, 0, 0, 25),
						Position = UDim2.fromOffset(0, 20),
						OnChanged = function(text)
						local val = tonumber(text)
						if val and val > 0 then
							setUiScale(val)
						end
					end,
					}),
				}),
				
				InfoLabel = React.createElement(StudioComponents.Label, {
					Text = "Scale down to fit high resolution screens into this widget.",
					Size = UDim2.new(1, 0, 0, 40),
					TextWrapped = true,
					TextColorStyle = Enum.StudioStyleGuideColor.DimmedText,
					LayoutOrder = 5,
				}),
			})
		})
	})
end

return PreviewTab
