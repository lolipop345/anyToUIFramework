local React = require(script.Parent.Parent:FindFirstChild('node_modules'):FindFirstChild('luau-aliases'):FindFirstChild('@jsdotlua'):FindFirstChild('react'))

export type PluginContext = {
	plugin: Plugin,
	pushMouseIcon: (icon: string) -> string,
	popMouseIcon: (id: string) -> ()
}

return React.createContext(nil :: PluginContext?)
