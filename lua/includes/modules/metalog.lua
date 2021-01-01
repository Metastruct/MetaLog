--[[
	This file is part of MetaLog, Copyright 2021 PotcFdk

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]]

--luacheck: globals metalog

if metalog then return end -- because require() has forever been broken in gmod, even now in 2021!

-- helpers

local function assertType (name, var, expected_type, expected_type_print_override)
	if type (var) ~= expected_type then
		return error (string.format ("Invalid type for %s: %s (%s) given, but expected %s",
			name, tostring (var), type (var), expected_type_print_override or expected_type))
	end
end

-- global shared environment used for storing settings and handlers

local ml_console_printer = include ("metalog_handlers/ml_console_printer.lua")

--luacheck: globals _metalogEnv
_metalogEnv = _metalogEnv or {
	sinks = {
		ml_console_printer = ml_console_printer
	}
}

-- levels

--luacheck: globals METALOG_LEVEL_NONE METALOG_LEVEL_FATAL METALOG_LEVEL_ERROR METALOG_LEVEL_WARN METALOG_LEVEL_INFO METALOG_LEVEL_DEBUG, ignore
METALOG_LEVEL_NONE  =   0
METALOG_LEVEL_FATAL = 2^0
METALOG_LEVEL_ERROR = 2^1
METALOG_LEVEL_WARN  = 2^2
METALOG_LEVEL_INFO  = 2^3
METALOG_LEVEL_DEBUG = 2^4

local levelNames = {
	[  0] = "none",
	[2^0] = "fatal",
	[2^1] = "error",
	[2^2] = "warn",
	[2^3] = "info",
	[2^4] = "debug"
}

local function getLevelName (level)
	return levelNames [level] or "?"
end

-- logging backend management

local function registerLoggingSink (name, callback)
	assertType ("name", name, "string")
	assertType ("callback", callback, "function")

	_metalogEnv.sinks = _metalogEnv.sinks or {}
	_metalogEnv.sinks [name] = callback
end

local function unregisterLoggingSink (name)
	assertType ("name", name, "string")
	if _metalogEnv.sinks then
		_metalogEnv.sinks [name] = nil
	end
end

local function unregisterLoggingSinks ()
	if _metalogEnv.sinks then
		table.Empty (_metalogEnv.sinks)
	end
end

-- central internal logging interface

local function log (id, channel, level, message, ...)
	for sinkName, sink in next, _metalogEnv.sinks do
		local ok, err = pcall (sink, id, channel, level, message, ...)
		if not ok then
			_metalogEnv.sinks [sinkName] = nil
			ml_console_printer ("MetaLog", "sinks", METALOG_LEVEL_WARN,
				"Logging sink '%s' has errored and has been removed. The error was: %s",
				sinkName, err)
		end
	end
end

-- per-level logging aliases

local function logFatal (id, channel, message, ...) return log (id, channel, METALOG_LEVEL_FATAL, message, ...) end
local function logError (id, channel, message, ...) return log (id, channel, METALOG_LEVEL_ERROR, message, ...) end
local function logWarn  (id, channel, message, ...) return log (id, channel, METALOG_LEVEL_WARN,  message, ...) end
local function logInfo  (id, channel, message, ...) return log (id, channel, METALOG_LEVEL_INFO,  message, ...) end
local function logDebug (id, channel, message, ...) return log (id, channel, METALOG_LEVEL_DEBUG, message, ...) end

-- OO / metatable things

local META_LOGGER = {
	__index = function (_, key)
		if     key == 'log'   then return function (logger, ...) return log      (logger.id, logger.channel, ...) end
		elseif key == 'fatal' then return function (logger, ...) return logFatal (logger.id, logger.channel, ...) end
		elseif key == 'error' then return function (logger, ...) return logError (logger.id, logger.channel, ...) end
		elseif key == 'warn'  then return function (logger, ...) return logWarn  (logger.id, logger.channel, ...) end
		elseif key == 'info'  then return function (logger, ...) return logInfo  (logger.id, logger.channel, ...) end
		elseif key == 'debug' then return function (logger, ...) return logDebug (logger.id, logger.channel, ...) end
		end
	end
}

local function __call (_, id, channel)
	assertType ("id", id, "string")
	if channel ~= nil then
		assertType ("channel", channel, "string", "optional string")
	end

	return setmetatable({
		id = id,
		channel = channel
	}, META_LOGGER)
end

metalog = setmetatable ({
	METALOG_LEVEL_NONE  = METALOG_LEVEL_NONE,
	METALOG_LEVEL_FATAL = METALOG_LEVEL_FATAL,
	METALOG_LEVEL_ERROR = METALOG_LEVEL_ERROR,
	METALOG_LEVEL_WARN  = METALOG_LEVEL_WARN,
	METALOG_LEVEL_INFO  = METALOG_LEVEL_INFO,
	METALOG_LEVEL_DEBUG = METALOG_LEVEL_DEBUG,

	log   = log,
	fatal = logFatal,
	error = logError,
	warn  = logWarn,
	info  = logInfo,
	debug = logDebug,

	getLevelName = getLevelName
}, {
	__call = __call
})

return metalog
