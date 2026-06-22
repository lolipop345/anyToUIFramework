local Converters = {
	Vide = require(script:WaitForChild("VideConverter")),
	Roact = require(script:WaitForChild("RoactConverter")),
	React = require(script:WaitForChild("ReactConverter")),
	Fusion2 = require(script:WaitForChild("Fusion2Converter")),
	Fusion3 = require(script:WaitForChild("Fusion3Converter")),
	Legacy = require(script:WaitForChild("LegacyConverter")),
	PropertyHelper = require(script:WaitForChild("PropertyHelper")),
}

return Converters
