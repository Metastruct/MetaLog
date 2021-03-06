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

local function assertLevel (level)
	if type (level) ~= "number" or (
		    level ~= METALOG_LEVEL_NONE
		and level ~= METALOG_LEVEL_FATAL
		and level ~= METALOG_LEVEL_ERROR
		and level ~= METALOG_LEVEL_WARN
		and level ~= METALOG_LEVEL_INFO
		and level ~= METALOG_LEVEL_DEBUG
	) then
		return error (string.format ("Invalid level '%s'.", tostring (level)))
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

METALOG_LEVEL_NONE  =   0
METALOG_LEVEL_FATAL = 2^0
METALOG_LEVEL_ERROR = 2^1
METALOG_LEVEL_WARN  = 2^2
METALOG_LEVEL_INFO  = 2^3
METALOG_LEVEL_DEBUG = 2^4

local levelNames = {
	[METALOG_LEVEL_NONE]  = "none",
	[METALOG_LEVEL_FATAL] = "fatal",
	[METALOG_LEVEL_ERROR] = "error",
	[METALOG_LEVEL_WARN]  = "warn",
	[METALOG_LEVEL_INFO]  = "info",
	[METALOG_LEVEL_DEBUG] = "debug"
}

local function getLevelName (level)
	return levelNames [level] or "?"
end

-- logging backend management

local function getLoggingSink (id)
	assertType ("id", id, "string")
	return _metalogEnv.sinks and _metalogEnv.sinks [id]
end

local function registerLoggingSink (id, sink)
	assertType ("id", id, "string")
	assertType ("sink", sink, "table")
	assertType ("sink.onMessage", sink.onMessage, "function")
	if sink.onColorMessage ~= nil then
		assertType ("sink.onColorMessage", sink.onColorMessage, "function", "optional function")
	end
	if sink.translateColorMessages ~= nil then
		assertType ("sink.translateColorMessages", sink.translateColorMessages, "boolean", "optional boolean")
	end
	if not sink.onColorMessage and not sink.translateColorMessages then
		error ("Invalid sink configuration: no onColorMessage implementation provided and translateColorMessages not specified."
			.. " Sink must somehow be able to receive color messages!")
	end
	_metalogEnv.sinks = _metalogEnv.sinks or {}
	_metalogEnv.sinks [id] = sink
end

local function unregisterLoggingSink (id)
	assertType ("id", id, "string")
	if _metalogEnv.sinks then
		_metalogEnv.sinks [id] = nil
	end
end

local function unregisterLoggingSinks ()
	if _metalogEnv.sinks then
		table.Empty (_metalogEnv.sinks)
	end
end

-- helpers

local colorKeys = { r = true, g = true, b = true, a = true }

local function isColor (color)
	if type (color) ~= "table" then return end
	if IsColor and IsColor (color) then return true end
	for k in next, color do
		if not colorKeys [k] then
			return false
		end
	end
	return true
end

-- central internal logging interface

local function Ilog (isColorMode, id, channel, level, ...)
	assertType ("id", id, "string")
	if channel ~= nil then
		assertType ("channel", channel, "string", "optional string")
	end
	assertLevel (level)

	for sinkName, sink in next, _metalogEnv.sinks do
		local ok, err

		if isColorMode then
			if sink.translateColorMessages then
				local dataWithColorsStripped, i = {...}, 1
				while i < #dataWithColorsStripped do
					if isColor (dataWithColorsStripped [i]) then
						table.remove (dataWithColorsStripped, i)
					else
						i = i + 1
					end
				end
				ok, err = pcall (sink.onMessage, id, channel, level, unpack (dataWithColorsStripped))
			else
				ok, err = pcall (sink.onColorMessage, id, channel, level, ...)
			end
		else
			ok, err = pcall (sink.onMessage, id, channel, level, ...)
		end

		if not ok then
			_metalogEnv.sinks [sinkName] = nil
			ml_console_printer.onMessage ("MetaLog", "sinks", METALOG_LEVEL_WARN,
				string.format ("Logging sink '%s' has errored and has been removed. The error was: %s",
					sinkName, err)
				)
		end
	end
end

local function log (...)
	return Ilog (false, ...)
end

local function logColor (...)
	return Ilog (true, ...)
end

-- per-level logging aliases

local function logFatal (id, channel, ...) return log (id, channel, METALOG_LEVEL_FATAL, ...) end
local function logError (id, channel, ...) return log (id, channel, METALOG_LEVEL_ERROR, ...) end
local function logWarn  (id, channel, ...) return log (id, channel, METALOG_LEVEL_WARN,  ...) end
local function logInfo  (id, channel, ...) return log (id, channel, METALOG_LEVEL_INFO,  ...) end
local function logDebug (id, channel, ...) return log (id, channel, METALOG_LEVEL_DEBUG, ...) end

local function logFatalColor (id, channel, ...) return logColor (id, channel, METALOG_LEVEL_FATAL, ...) end
local function logErrorColor (id, channel, ...) return logColor (id, channel, METALOG_LEVEL_ERROR, ...) end
local function logWarnColor  (id, channel, ...) return logColor (id, channel, METALOG_LEVEL_WARN,  ...) end
local function logInfoColor  (id, channel, ...) return logColor (id, channel, METALOG_LEVEL_INFO,  ...) end
local function logDebugColor (id, channel, ...) return logColor (id, channel, METALOG_LEVEL_DEBUG, ...) end

local function logFormat      (id, channel, level, message, ...) return log      (id, channel, level, string.format (message, ...)) end
local function logFatalFormat (id, channel,        message, ...) return logFatal (id, channel,        string.format (message, ...)) end
local function logErrorFormat (id, channel,        message, ...) return logError (id, channel,        string.format (message, ...)) end
local function logWarnFormat  (id, channel,        message, ...) return logWarn  (id, channel,        string.format (message, ...)) end
local function logInfoFormat  (id, channel,        message, ...) return logInfo  (id, channel,        string.format (message, ...)) end
local function logDebugFormat (id, channel,        message, ...) return logDebug (id, channel,        string.format (message, ...)) end

-- OO / metatable things

local META_LOGGER = {
	__index = function (_, key)
		if     key == 'log'   then return function (logger, level, ...) return log (logger.id, logger.channel, level, ...) end
		elseif key == 'fatal' then return function (logger, ...) return logFatal (logger.id, logger.channel, ...) end
		elseif key == 'error' then return function (logger, ...) return logError (logger.id, logger.channel, ...) end
		elseif key == 'warn'  then return function (logger, ...) return logWarn  (logger.id, logger.channel, ...) end
		elseif key == 'info'  then return function (logger, ...) return logInfo  (logger.id, logger.channel, ...) end
		elseif key == 'debug' then return function (logger, ...) return logDebug (logger.id, logger.channel, ...) end

		elseif key == 'logColor'   then return function (logger, level, ...) return logColor (logger.id, level, logger.channel, ...) end
		elseif key == 'fatalColor' then return function (logger, ...) return logFatalColor (logger.id, logger.channel, ...) end
		elseif key == 'errorColor' then return function (logger, ...) return logErrorColor (logger.id, logger.channel, ...) end
		elseif key == 'warnColor'  then return function (logger, ...) return logWarnColor  (logger.id, logger.channel, ...) end
		elseif key == 'infoColor'  then return function (logger, ...) return logInfoColor  (logger.id, logger.channel, ...) end
		elseif key == 'debugColor' then return function (logger, ...) return logDebugColor (logger.id, logger.channel, ...) end

		elseif key == 'logFormat'   then return function (logger, level, message, ...) return logFormat (logger.id, logger.channel, level, message, ...) end
		elseif key == 'fatalFormat' then return function (logger, message, ...) return logFatalFormat (logger.id, logger.channel, message, ...) end
		elseif key == 'errorFormat' then return function (logger, message, ...) return logErrorFormat (logger.id, logger.channel, message, ...) end
		elseif key == 'warnFormat'  then return function (logger, message, ...) return logWarnFormat  (logger.id, logger.channel, message, ...) end
		elseif key == 'infoFormat'  then return function (logger, message, ...) return logInfoFormat  (logger.id, logger.channel, message, ...) end
		elseif key == 'debugFormat' then return function (logger, message, ...) return logDebugFormat (logger.id, logger.channel, message, ...) end
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

	getLoggingSink         = getLoggingSink,
	registerLoggingSink    = registerLoggingSink,
	unregisterLoggingSink  = unregisterLoggingSink,
	unregisterLoggingSinks = unregisterLoggingSinks,

	isColor = isColor,

	log   = log,
	fatal = logFatal,
	error = logError,
	warn  = logWarn,
	info  = logInfo,
	debug = logDebug,

	logColor   = logColor,
	fatalColor = logFatalColor,
	errorColor = logErrorColor,
	warnColor  = logWarnColor,
	infoColor  = logInfoColor,
	debugColor = logDebugColor,

	logFormat   = logFormat,
	fatalFormat = logFatalFormat,
	errorFormat = logErrorFormat,
	warnFormat  = logWarnFormat,
	infoFormat  = logInfoFormat,
	debugFormat = logDebugFormat,

	getLevelName = getLevelName
}, {
	__call = __call
})

return metalog
