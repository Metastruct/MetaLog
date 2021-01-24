allow_defined_top = true
exclude_files = {".install", ".luarocks"}
read_globals = {
	"METALOG_LEVEL_NONE",
	"METALOG_LEVEL_FATAL",
	"METALOG_LEVEL_ERROR",
	"METALOG_LEVEL_WARN",
	"METALOG_LEVEL_INFO",
	"METALOG_LEVEL_DEBUG",
	"metalog",
	"include",
	"unpack",
	"Color",
	"CreateConVar",
	table = {
		fields = {
			"Empty", "GetKeys"
		}
	}
}
max_line_length = false
std = "lua53"
files ["tests/test_ext_table.lua"] = {
	globals = {
		table = {
			fields = {
				"Empty", "GetKeys"
			}
		}
	}
}
files ["lua/includes/modules/metalog.lua"] = {
	read_globals = {
		"IsColor"
	}
}
files ["tests/test_mock.lua"] = {
	read_globals = {
		"__MOCK_GMOD_RESET_CONVAR"
	}
}
files ["tests/test.lua"] = {
	read_globals = {
		"__MOCK_GMOD_RESET_CONVAR"
	}
}
files [".luacheckrc"] = {
	global = false
}
files [".luacov"] = {
	global = false
}