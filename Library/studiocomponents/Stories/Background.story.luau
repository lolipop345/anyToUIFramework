local React = require(script.Parent.Parent:FindFirstChild('node_modules'):FindFirstChild('.luau-aliases'):FindFirstChild('@jsdotlua'):FindFirstChild('react'))

local Background = require(script.Parent.Parent:FindFirstChild('Components'):FindFirstChild('Background'))
local createStory = require(script.Parent:FindFirstChild('Helpers'):FindFirstChild('createStory'))

local function Story()
	return React.createElement(Background)
end

return createStory(Story)
