return {
	CreateConVar = function (var, default)
		return {
			GetString = function()
				return default
			end
		}
	end,
	Color = function (r, g, b, a)
		return {
			r = math.min (tonumber (r) or 0, 255),
			g = math.min (tonumber (g) or 0, 255),
			b = math.min (tonumber (b) or 0, 255),
			a = math.min (tonumber (a) or 0, 255)
		}
	end
}