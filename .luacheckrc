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
	table = {
		fields = {
			"Empty"
		}
	}
}
max_line_length = false
std = "lua53"
files ["tests/test_ext_table.lua"] = {
	globals = {
		table = {
			fields = {
				"Empty"
			}
		}
	}
}
files [".luacheckrc"] = {
	global = false
}