--!nocheck

local React = require(script.Parent.Parent.Parent:FindFirstChild('node_modules'):FindFirstChild('.luau-aliases'):FindFirstChild('@jsdotlua'):FindFirstChild('react'))
local ReactRoblox = require(script.Parent.Parent.Parent:FindFirstChild('node_modules'):FindFirstChild('.luau-aliases'):FindFirstChild('@jsdotlua'):FindFirstChild('react-roblox'))

return {
	name = "StudioComponents",
	storyRoots = {
		script.Parent.Parent,
	},
	packages = {
		React = React,
		ReactRoblox = ReactRoblox,
	},
}
