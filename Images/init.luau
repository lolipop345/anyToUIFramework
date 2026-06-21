local Images = {}

setmetatable(Images, {
	__index = function(self, key)
		local child = script:FindFirstChild(key)
		if child and child:IsA("ModuleScript") then
			local value = require(child)
			self[key] = value
			return value
		end
		return nil
	end
})

return Images
