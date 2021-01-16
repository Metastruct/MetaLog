_G.__MOCK_GMOD_CONVARS = {}

function _G.__MOCK_GMOD_RESET_CONVAR (id)
	_G.__MOCK_GMOD_CONVARS [id] = nil
end

_G.__CONSOLE_PRINTER_NONE = true

return {
	CreateConVar = function (id, default)
		_G.__MOCK_GMOD_CONVARS [id] = _G.__MOCK_GMOD_CONVARS [id] or default
		return {
			GetString = function ()
				if _G.__CONSOLE_PRINTER_NONE then return "NONE" end
				return _G.__MOCK_GMOD_CONVARS [id]
			end,
			SetString = function (_, newVal)
				_G.__MOCK_GMOD_CONVARS [id] = newVal
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