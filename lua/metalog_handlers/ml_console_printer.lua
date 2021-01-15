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

--luacheck: globals METALOG_LEVEL_NONE METALOG_LEVEL_FATAL METALOG_LEVEL_ERROR METALOG_LEVEL_WARN METALOG_LEVEL_INFO METALOG_LEVEL_DEBUG, ignore

local cLogLevel = CreateConVar ("metalog_console_log_level", "info", nil,
	[[The log level that is used by the default MetaLog console printer.
	Available levels (cumulative, so "warn" would, for example, also include "error" and "fatal"):
	- none (disable all logging)
	- fatal (only logs that concern errors that cause a full-scale breakage of scripts)
	- error (all other errors that indicate unintended behavior)
	- warn (warnings that are not yet quite errors but deserve some attention)
	- info (purely informative messages) (default)
	- debug (verbose messages of mostly developer value, potentially very noisy)]])

local COLOR_BRACKETS          = Color (200, 200, 200)
local COLOR_ID                = Color (255, 255, 255)
local COLOR_CHANNEL_SEPARATOR = COLOR_BRACKETS
local COLOR_CHANNEL           = COLOR_ID

local COLOR_FATAL = Color (255,   0,   0)
local COLOR_ERROR = Color (255, 100, 100)
local COLOR_WARN  = Color (255, 255,  50)
local COLOR_INFO  = Color (100, 100, 255)
local COLOR_DEBUG = Color (255, 255, 255)

local COLORS_BY_LEVEL = {
	[2^0] = COLOR_FATAL,
	[2^1] = COLOR_ERROR,
	[2^2] = COLOR_WARN,
	[2^3] = COLOR_INFO,
	[2^4] = COLOR_DEBUG
}

return function (id, channel, level, ...)
	-- map the convar setting to one of the supported log levels, default to INFO

	local logLevel = cLogLevel:GetString():gsub ("[^%a]", ""):upper()
	if _G["METALOG_LEVEL_" .. logLevel] then
		logLevel = _G["METALOG_LEVEL_" .. logLevel]
	else
		logLevel = METALOG_LEVEL_INFO
		cLogLevel:SetString ("info")
	end

	-- this is just a simple level-cut-off for now,
	-- checking if the configured log level is greater or equal than the message's level

	if level <= logLevel then
		MsgC (COLOR_BRACKETS, "[", COLOR_ID, id,
			COLOR_CHANNEL_SEPARATOR, channel and "/" or "", COLOR_CHANNEL, channel or "", COLOR_BRACKETS, ":",
			COLORS_BY_LEVEL [level] or COLOR_DEBUG, metalog.getLevelName (level),
			COLOR_BRACKETS, "] ")
		print (...)
	end
end
