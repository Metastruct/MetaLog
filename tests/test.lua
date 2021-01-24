package.path = './?/?.lua;./?/lua.lua;./?.lua;./tests/?.lua;./lua/includes/modules/?.lua;' .. package.path

_G.include = function (path)
	return dofile ("lua/" .. path)
end

for k, v in next, require ('test_mock') do
	_G[k] = v
end
for k, v in next, require ('test_ext_misc') do
	_G[k] = v
end

require ('test_ext_table')

lu = require ('luaunit')
require ('metalog')

function lu.assertIsLessThan (a, b)
	if not (a < b) then
		return lu.fail (string.format ("expected: %s < %s", lu.private.prettystrPairs (a, b)))
	end
end

lu.assertIsTable (metalog)

local function NOT_A_STRING () end

local function MAKE_LOGGING_SINK_NOCOLOR ()
	local received
	return function() return received end, {
		onMessage = function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end,
		translateColorMessages = true
	}
end

local function MAKE_LOGGING_SINK_COLOR ()
	local received, receivedColor
	return function() return received, receivedColor end, {
		onMessage = function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end,
		onColorMessage = function (id, channel, level, ...)
			receivedColor = {id=id, channel=channel, level=level, ...}
		end,
	}
end

local function MAKE_RANDOM_PAYLOAD ()
	return { math.random(), Color (1, 2, 3), math.random(), Color (1, 2, 3), Color (1, 2, 3), math.random() }
end

function lu.assertArrayMatchesSequentially (a, b)
	local i = 1
	lu.assertIsTable (a)
	lu.assertIsTable (b)
	if #a ~= #b then
		lu.fail (string.format ("expected: array lengths %d == %d", #a, #b))
	end
	while true do
		if a[i] or b[i] then
			if a[i] ~= b[i] then
				local _a, _b = lu.private.prettystrPairs (a[i], b[i])
				return lu.fail (string.format ("expected: %s == %s at array index %d\nExpected = %s\nReceived = %s", _a, _b, i, lu.private.prettystrPairs (a, b)))
			end
			lu.assertIs (a[i], b[i])
		else
			return
		end
		i = i + 1
	end
end

function lu.assertArrayMatchesSequentiallyExceptColors (a, b)
	local aNoColors, bNoColors = {}, {}
	for i = 1, #a do
		if not metalog.isColor (a[i]) then
			table.insert (aNoColors, a[i])
		end
	end
	for i = 1, #b do
		if not metalog.isColor (b[i]) then
			table.insert (bNoColors, b[i])
		end
	end
	return lu.assertArrayMatchesSequentially (aNoColors, bNoColors)
end

--

TestLevelInterface = {}
	function TestLevelInterface.testLevels ()
		lu.assertIsNumber (METALOG_LEVEL_NONE)
		lu.assertIsNumber (METALOG_LEVEL_FATAL)
		lu.assertIsNumber (METALOG_LEVEL_ERROR)
		lu.assertIsNumber (METALOG_LEVEL_WARN)
		lu.assertIsNumber (METALOG_LEVEL_INFO)
		lu.assertIsNumber (METALOG_LEVEL_DEBUG)
	end

	function TestLevelInterface.testLevelOrder ()
		lu.assertIsLessThan (METALOG_LEVEL_NONE, METALOG_LEVEL_FATAL)
		lu.assertIsLessThan (METALOG_LEVEL_FATAL, METALOG_LEVEL_ERROR)
		lu.assertIsLessThan (METALOG_LEVEL_ERROR, METALOG_LEVEL_WARN)
		lu.assertIsLessThan (METALOG_LEVEL_WARN, METALOG_LEVEL_INFO)
		lu.assertIsLessThan (METALOG_LEVEL_INFO, METALOG_LEVEL_DEBUG)
	end

	function TestLevelInterface.testLevelNames ()
		lu.assertIs (metalog.getLevelName (METALOG_LEVEL_NONE),  "none")
		lu.assertIs (metalog.getLevelName (METALOG_LEVEL_FATAL), "fatal")
		lu.assertIs (metalog.getLevelName (METALOG_LEVEL_ERROR), "error")
		lu.assertIs (metalog.getLevelName (METALOG_LEVEL_WARN),  "warn")
		lu.assertIs (metalog.getLevelName (METALOG_LEVEL_INFO),  "info")
		lu.assertIs (metalog.getLevelName (METALOG_LEVEL_DEBUG), "debug")
	end

-- TestSinkInterface
TestSinkInterface = {}
	function TestSinkInterface.setUp ()
		metalog.unregisterLoggingSinks()
	end

	function TestSinkInterface.testSetLoggingSinkInvalidTypes ()
		lu.assertErrorMsgContains ("Invalid type for sink", metalog.registerLoggingSink, "test")
		lu.assertErrorMsgContains ("Invalid type for sink", metalog.registerLoggingSink, "test", false)
		lu.assertErrorMsgContains ("Invalid type for sink", metalog.registerLoggingSink, "test", true)
		lu.assertErrorMsgContains ("Invalid type for sink", metalog.registerLoggingSink, "test", 123)
		lu.assertErrorMsgContains ("Invalid type for sink", metalog.registerLoggingSink, "test", function()end)

		local validSink = {onMessage=function()end, onColorMessage=function()end}

		lu.assertErrorMsgContains ("Invalid type for id", metalog.registerLoggingSink, nil, validSink)
		lu.assertErrorMsgContains ("Invalid type for id", metalog.registerLoggingSink, true, validSink)
		lu.assertErrorMsgContains ("Invalid type for id", metalog.registerLoggingSink, false, validSink)
		lu.assertErrorMsgContains ("Invalid type for id", metalog.registerLoggingSink, 123, validSink)
		lu.assertErrorMsgContains ("Invalid type for id", metalog.registerLoggingSink, function()end, validSink)
		lu.assertErrorMsgContains ("Invalid type for id", metalog.registerLoggingSink, {}, validSink)

		lu.assertErrorMsgContains ("Invalid type for sink.onMessage", metalog.registerLoggingSink, "test", {onColorMessage=function()end})
		lu.assertErrorMsgContains ("Invalid type for sink.translateColorMessage", metalog.registerLoggingSink, "test", {onMessage = function()end, translateColorMessages = "wrong"})
		lu.assertErrorMsgContains ("Invalid type for sink.translateColorMessage", metalog.registerLoggingSink, "test", {onMessage = function()end, translateColorMessages = function()end})
		lu.assertErrorMsgContains ("Invalid type for sink.translateColorMessage", metalog.registerLoggingSink, "test", {onMessage = function()end, translateColorMessages = 123})
		lu.assertErrorMsgContains ("Invalid type for sink.translateColorMessage", metalog.registerLoggingSink, "test", {onMessage = function()end, translateColorMessages = {}})

		lu.assertErrorMsgContains ("Invalid sink configuration", metalog.registerLoggingSink, "test", {onMessage = function()end})
		lu.assertErrorMsgContains ("Invalid sink configuration", metalog.registerLoggingSink, "test", {onMessage = function()end, translateColorMessages = false})

		metalog.registerLoggingSink ("test", validSink)
		metalog.registerLoggingSink ("test", {onMessage = function()end, translateColorMessages = true})
	end

	function TestSinkInterface.testGetLoggingSink ()
		local id = string.format ("Rnd%f", math.random())

		lu.assertIsNil (metalog.getLoggingSink (id..1))
		lu.assertIsNil (metalog.getLoggingSink (id..2))

		local sink1 = {onMessage = function()end, translateColorMessages = true}
		local sink2 = {onMessage = function()end, translateColorMessages = true}

		metalog.registerLoggingSink (id..1, sink1)
		metalog.registerLoggingSink (id..2, sink2)

		lu.assertIs (metalog.getLoggingSink (id..1), sink1)
		lu.assertIs (metalog.getLoggingSink (id..2), sink2)

		metalog.unregisterLoggingSink (id..1)
		lu.assertIsNil (metalog.getLoggingSink (id..1))
		lu.assertIs (metalog.getLoggingSink (id..2), sink2)

		metalog.unregisterLoggingSinks()
		lu.assertIsNil (metalog.getLoggingSink (id..1))
		lu.assertIsNil (metalog.getLoggingSink (id..2))
	end

	function TestSinkInterface.testErroringLoggingSink ()
		lu.assertIsNil (metalog.getLoggingSink ("testing"))

		local A, B

		local sinkA   = { onMessage = function (id) A = id end, translateColorMessages = true }
		local sinkB   = { onMessage = function (id) B = id end, translateColorMessages = true }
		local sinkErr = { onMessage = function () error ("ERROR_ALWAYS") end, translateColorMessages = true }

		metalog.registerLoggingSink ("testing1", sinkA)
		metalog.registerLoggingSink ("testing2", sinkErr)
		metalog.registerLoggingSink ("testing3", sinkB)

		lu.assertIs (metalog.getLoggingSink ("testing1"), sinkA)
		lu.assertIs (metalog.getLoggingSink ("testing2"), sinkErr)
		lu.assertIs (metalog.getLoggingSink ("testing3"), sinkB)

		metalog.debug ("example", nil, "An example log message.")

		lu.assertIs    (metalog.getLoggingSink ("testing1"), sinkA)
		lu.assertIsNil (metalog.getLoggingSink ("testing2"))
		lu.assertIs    (metalog.getLoggingSink ("testing3"), sinkB)

		lu.assertIs (A, "example")
		lu.assertIs (B, "example")
	end

TestLoggingStatic = {}
	function TestLoggingStatic.setUp ()
		metalog.unregisterLoggingSinks()
	end

	local function testCaseForLogStatic (testLevel, testChannel)
		do -- nocolor sink with translateColorMessages fallback
			local get, sink = MAKE_LOGGING_SINK_NOCOLOR()
			metalog.registerLoggingSink ("testing", sink)

			do -- nocolor message
				local payload = MAKE_RANDOM_PAYLOAD()

				metalog.log ("test:id", testChannel, testLevel, table.unpack (payload))

				lu.assertErrorMsgContains ("Invalid level", metalog.log, "test:id", testChannel, NOT_A_STRING, table.unpack (payload))
				lu.assertErrorMsgContains ("Invalid type for channel", metalog.log, "test:id", NOT_A_STRING, testLevel, table.unpack (payload))

				local received = get()
				lu.assertIs (received.id, "test:id")
				lu.assertIs (received.channel, testChannel)
				lu.assertIs (received.level, testLevel)
				lu.assertArrayMatchesSequentially (received, payload)
			end
			do -- color message
				local payload = MAKE_RANDOM_PAYLOAD()

				metalog.logColor ("test:id", testChannel, testLevel, table.unpack (payload))

				lu.assertErrorMsgContains ("Invalid level", metalog.logColor, "test:id", testChannel, NOT_A_STRING, table.unpack (payload))
				lu.assertErrorMsgContains ("Invalid type for channel", metalog.logColor, "test:id", NOT_A_STRING, testLevel, table.unpack (payload))

				local received = get()
				lu.assertIs (received.id, "test:id")
				lu.assertIs (received.channel, testChannel)
				lu.assertIs (received.level, testLevel)
				lu.assertArrayMatchesSequentiallyExceptColors (received, payload)
			end
		end
		do -- color sink
			local get, sink = MAKE_LOGGING_SINK_COLOR()
			metalog.registerLoggingSink ("testing", sink)

			local payload = MAKE_RANDOM_PAYLOAD()
			local payloadColor = MAKE_RANDOM_PAYLOAD()

			metalog.log ("test:id", testChannel, testLevel, table.unpack (payload))
			metalog.logColor ("test:id", testChannel, testLevel, table.unpack (payloadColor))

			local received, receivedColor = get()

			lu.assertIs (received.id, "test:id")
			lu.assertIs (received.channel, testChannel)
			lu.assertIs (received.level, testLevel)
			lu.assertArrayMatchesSequentially (received, payload)

			lu.assertIs (receivedColor.id, "test:id")
			lu.assertIs (receivedColor.channel, testChannel)
			lu.assertIs (receivedColor.level, testLevel)
			lu.assertArrayMatchesSequentially (receivedColor, payloadColor)
		end
	end

	function TestLoggingStatic.testLogFatal () testCaseForLogStatic (METALOG_LEVEL_FATAL) end
	function TestLoggingStatic.testLogError () testCaseForLogStatic (METALOG_LEVEL_ERROR) end
	function TestLoggingStatic.testLogWarn  () testCaseForLogStatic (METALOG_LEVEL_WARN)  end
	function TestLoggingStatic.testLogInfo  () testCaseForLogStatic (METALOG_LEVEL_INFO)  end
	function TestLoggingStatic.testLogDebug () testCaseForLogStatic (METALOG_LEVEL_DEBUG) end

	function TestLoggingStatic.testLogFatalChannel () testCaseForLogStatic (METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingStatic.testLogErrorChannel () testCaseForLogStatic (METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingStatic.testLogWarnChannel  () testCaseForLogStatic (METALOG_LEVEL_WARN , "test_channel") end
	function TestLoggingStatic.testLogInfoChannel  () testCaseForLogStatic (METALOG_LEVEL_INFO , "test_channel") end
	function TestLoggingStatic.testLogDebugChannel () testCaseForLogStatic (METALOG_LEVEL_DEBUG, "test_channel") end

	local function testCaseForLevelStatic (func, funcColor, expectedLevel, testChannel)
		do -- nocolor sink with translateColorMessages fallback
			local get, sink = MAKE_LOGGING_SINK_NOCOLOR()
			metalog.registerLoggingSink ("testing", sink)

			do -- nocolor message
				local payload = MAKE_RANDOM_PAYLOAD()

				func ("test:id", testChannel, table.unpack (payload))

				lu.assertErrorMsgContains ('Invalid type for channel', func, "test:id", NOT_A_STRING, table.unpack (payload))

				local received = get()
				lu.assertIs (received.id, "test:id")
				lu.assertIs (received.channel, testChannel)
				lu.assertIs (received.level, expectedLevel)
				lu.assertArrayMatchesSequentially (received, payload)
			end
			do -- color message
				local payload = MAKE_RANDOM_PAYLOAD()

				funcColor ("test:id", testChannel, table.unpack (payload))

				lu.assertErrorMsgContains ('Invalid type for channel', funcColor, "test:id", NOT_A_STRING, table.unpack (payload))

				local received = get()
				lu.assertIs (received.id, "test:id")
				lu.assertIs (received.channel, testChannel)
				lu.assertIs (received.level, expectedLevel)
				lu.assertArrayMatchesSequentiallyExceptColors (received, payload)
			end
		end
		do -- color sink
			local get, sink = MAKE_LOGGING_SINK_COLOR()
			metalog.registerLoggingSink ("testing", sink)

			local payload = MAKE_RANDOM_PAYLOAD()
			local payloadColor = MAKE_RANDOM_PAYLOAD()

			func ("test:id", testChannel, table.unpack (payload))
			funcColor ("test:id", testChannel, table.unpack (payloadColor))

			local received, receivedColor = get()

			lu.assertIs (received.id, "test:id")
			lu.assertIs (received.channel, testChannel)
			lu.assertIs (received.level, expectedLevel)
			lu.assertArrayMatchesSequentially (received, payload)

			lu.assertIs (receivedColor.id, "test:id")
			lu.assertIs (receivedColor.channel, testChannel)
			lu.assertIs (receivedColor.level, expectedLevel)
			lu.assertArrayMatchesSequentially (receivedColor, payloadColor)
		end
	end

	function TestLoggingStatic.testFatal () testCaseForLevelStatic (metalog.fatal, metalog.fatalColor, METALOG_LEVEL_FATAL) end
	function TestLoggingStatic.testError () testCaseForLevelStatic (metalog.error, metalog.errorColor, METALOG_LEVEL_ERROR) end
	function TestLoggingStatic.testWarn  () testCaseForLevelStatic (metalog.warn,  metalog.warnColor,  METALOG_LEVEL_WARN)  end
	function TestLoggingStatic.testInfo  () testCaseForLevelStatic (metalog.info,  metalog.infoColor,  METALOG_LEVEL_INFO)  end
	function TestLoggingStatic.testDebug () testCaseForLevelStatic (metalog.debug, metalog.debugColor, METALOG_LEVEL_DEBUG) end

	function TestLoggingStatic.testFatalChannel () testCaseForLevelStatic (metalog.fatal, metalog.fatalColor, METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingStatic.testErrorChannel () testCaseForLevelStatic (metalog.error, metalog.errorColor, METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingStatic.testWarnChannel  () testCaseForLevelStatic (metalog.warn,  metalog.warnColor,  METALOG_LEVEL_WARN,  "test_channel") end
	function TestLoggingStatic.testInfoChannel  () testCaseForLevelStatic (metalog.info,  metalog.infoColor,  METALOG_LEVEL_INFO,  "test_channel") end
	function TestLoggingStatic.testDebugChannel () testCaseForLevelStatic (metalog.debug, metalog.debugColor, METALOG_LEVEL_DEBUG, "test_channel") end

	local function testCaseForLogStaticFormat (testLevel, testChannel)
		local received
		metalog.registerLoggingSink ("testing", {
			onMessage = function (id, channel, level, ...)
				received = {id=id, channel=channel, level=level, ...}
			end,
			translateColorMessages = true
		})

		local payload = { math.random(), math.random(), "this one should be ignored" }

		metalog.logFormat ("test:id", testChannel, testLevel, "random numbers: %f %f", table.unpack (payload))

		lu.assertErrorMsgContains ("Invalid level", metalog.logFormat, "test:id", testChannel, NOT_A_STRING, "random numbers: %f %f", table.unpack (payload))
		lu.assertErrorMsgContains ("Invalid type for channel", metalog.logFormat, "test:id", NOT_A_STRING, testLevel, "random numbers: %f %f", table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIs (received.channel, testChannel)
		lu.assertIs (received.level, testLevel)
		lu.assertIs (received[1], string.format ("random numbers: %f %f", table.unpack (payload)))
		lu.assertIsNil (received[2])
		lu.assertIsNil (received[3])
	end

	function TestLoggingStatic.testLogFatalFormat () testCaseForLogStaticFormat (METALOG_LEVEL_FATAL) end
	function TestLoggingStatic.testLogErrorFormat () testCaseForLogStaticFormat (METALOG_LEVEL_ERROR) end
	function TestLoggingStatic.testLogWarnFormat  () testCaseForLogStaticFormat (METALOG_LEVEL_WARN)  end
	function TestLoggingStatic.testLogInfoFormat  () testCaseForLogStaticFormat (METALOG_LEVEL_INFO)  end
	function TestLoggingStatic.testLogDebugFormat () testCaseForLogStaticFormat (METALOG_LEVEL_DEBUG) end

	function TestLoggingStatic.testLogFatalFormatChannel () testCaseForLogStaticFormat (METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingStatic.testLogErrorFormatChannel () testCaseForLogStaticFormat (METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingStatic.testLogWarnFormatChannel  () testCaseForLogStaticFormat (METALOG_LEVEL_WARN,  "test_channel") end
	function TestLoggingStatic.testLogInfoFormatChannel  () testCaseForLogStaticFormat (METALOG_LEVEL_INFO,  "test_channel") end
	function TestLoggingStatic.testLogDebugFormatChannel () testCaseForLogStaticFormat (METALOG_LEVEL_DEBUG, "test_channel") end

	local function testCaseForLevelStaticFormat (func, expectedLevel, testChannel)
		local received
		metalog.registerLoggingSink ("testing", {
			onMessage = function (id, channel, level, ...)
				received = {id=id, channel=channel, level=level, ...}
			end,
			translateColorMessages = true
		})

		local payload = { math.random(), math.random(), "this one should be ignored" }

		func ("test:id", testChannel, "random numbers: %f %f", table.unpack (payload))

		lu.assertErrorMsgContains ("Invalid type for channel", func, "test:id", NOT_A_STRING, table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIs (received.channel, testChannel)
		lu.assertIs (received.level, expectedLevel)
		lu.assertIs (received[1], string.format ("random numbers: %f %f", table.unpack (payload)))
		lu.assertIsNil (received[2])
		lu.assertIsNil (received[3])
	end

	function TestLoggingStatic.testFatalFormat () testCaseForLevelStaticFormat (metalog.fatalFormat, METALOG_LEVEL_FATAL) end
	function TestLoggingStatic.testErrorFormat () testCaseForLevelStaticFormat (metalog.errorFormat, METALOG_LEVEL_ERROR) end
	function TestLoggingStatic.testWarnFormat  () testCaseForLevelStaticFormat (metalog.warnFormat,  METALOG_LEVEL_WARN)  end
	function TestLoggingStatic.testInfoFormat  () testCaseForLevelStaticFormat (metalog.infoFormat,  METALOG_LEVEL_INFO)  end
	function TestLoggingStatic.testDebugFormat () testCaseForLevelStaticFormat (metalog.debugFormat, METALOG_LEVEL_DEBUG) end

	function TestLoggingStatic.testFatalFormatChannel () testCaseForLevelStaticFormat (metalog.fatalFormat, METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingStatic.testErrorFormatChannel () testCaseForLevelStaticFormat (metalog.errorFormat, METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingStatic.testWarnFormatChannel  () testCaseForLevelStaticFormat (metalog.warnFormat,  METALOG_LEVEL_WARN,  "test_channel") end
	function TestLoggingStatic.testInfoFormatChannel  () testCaseForLevelStaticFormat (metalog.infoFormat,  METALOG_LEVEL_INFO,  "test_channel") end
	function TestLoggingStatic.testDebugFormatChannel () testCaseForLevelStaticFormat (metalog.debugFormat, METALOG_LEVEL_DEBUG, "test_channel") end

TestLoggingObject = {}
	function TestLoggingObject.setUp ()
		metalog.unregisterLoggingSinks()
	end

	local function testCaseForLevelObject (method, methodColor, expectedLevel, testChannel)
		do -- nocolor sink with translateColorMessages fallback
			local get, sink = MAKE_LOGGING_SINK_NOCOLOR()
			metalog.registerLoggingSink ("testing", sink)

			do -- nocolor message
				local payload = MAKE_RANDOM_PAYLOAD()

				local logger = metalog ("test:id", testChannel)
				logger[method] (logger, table.unpack (payload))

				local received = get()
				lu.assertIs (received.id, "test:id")
				lu.assertIs (received.channel, testChannel)
				lu.assertIs (received.level, expectedLevel)
				lu.assertArrayMatchesSequentially (received, payload)
			end
			do -- color message
				local payload = MAKE_RANDOM_PAYLOAD()

				local logger = metalog ("test:id", testChannel)
				logger[methodColor] (logger, table.unpack (payload))

				local received = get()
				lu.assertIs (received.id, "test:id")
				lu.assertIs (received.channel, testChannel)
				lu.assertIs (received.level, expectedLevel)
				lu.assertArrayMatchesSequentiallyExceptColors (received, payload)
			end
		end
		do -- color sink
			local get, sink = MAKE_LOGGING_SINK_COLOR()
			metalog.registerLoggingSink ("testing", sink)

			local payload = MAKE_RANDOM_PAYLOAD()
			local payloadColor = MAKE_RANDOM_PAYLOAD()

			local logger = metalog ("test:id", testChannel)
			logger[method] (logger, table.unpack (payload))
			logger[methodColor] (logger, table.unpack (payloadColor))

			local received, receivedColor = get()

			lu.assertIs (received.id, "test:id")
			lu.assertIs (received.channel, testChannel)
			lu.assertIs (received.level, expectedLevel)
			lu.assertArrayMatchesSequentially (received, payload)

			lu.assertIs (receivedColor.id, "test:id")
			lu.assertIs (receivedColor.channel, testChannel)
			lu.assertIs (receivedColor.level, expectedLevel)
			lu.assertArrayMatchesSequentially (receivedColor, payloadColor)
		end
	end

	function TestLoggingObject.testFatal () testCaseForLevelObject ("fatal", "fatalColor", METALOG_LEVEL_FATAL) end
	function TestLoggingObject.testError () testCaseForLevelObject ("error", "errorColor", METALOG_LEVEL_ERROR) end
	function TestLoggingObject.testWarn  () testCaseForLevelObject ("warn",  "warnColor",  METALOG_LEVEL_WARN)  end
	function TestLoggingObject.testInfo  () testCaseForLevelObject ("info",  "infoColor",  METALOG_LEVEL_INFO)  end
	function TestLoggingObject.testDebug () testCaseForLevelObject ("debug", "debugColor", METALOG_LEVEL_DEBUG) end

	function TestLoggingObject.testFatalChannel () testCaseForLevelObject ("fatal", "fatalColor", METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingObject.testErrorChannel () testCaseForLevelObject ("error", "errorColor", METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingObject.testWarnChannel  () testCaseForLevelObject ("warn",  "warnColor",  METALOG_LEVEL_WARN,  "test_channel") end
	function TestLoggingObject.testInfoChannel  () testCaseForLevelObject ("info",  "infoColor",  METALOG_LEVEL_INFO,  "test_channel") end
	function TestLoggingObject.testDebugChannel () testCaseForLevelObject ("debug", "debugColor", METALOG_LEVEL_DEBUG, "test_channel") end

	function TestLoggingObject.testInvalidChannel () lu.assertErrorMsgContains ('expected optional string', metalog, "test:id", NOT_A_STRING) end

	local function testCaseForLevelObjectFormat (method, expectedLevel, testChannel)
		local get, sink = MAKE_LOGGING_SINK_NOCOLOR()
		metalog.registerLoggingSink ("testing", sink)

		local payload = { math.random(), math.random(), "this one should be ignored" }

		local logger = metalog ("test:id", testChannel)
		logger[method] (logger, "random numbers: %f %f", table.unpack (payload))

		local received = get()
		lu.assertIs (received.id, "test:id")
		lu.assertIs (received.channel, testChannel)
		lu.assertIs (received.level, expectedLevel)
		lu.assertIs (received[1], string.format ("random numbers: %f %f", table.unpack (payload)))
		lu.assertIsNil (received[2])
		lu.assertIsNil (received[3])
	end

	function TestLoggingObject.testFatalFormat () testCaseForLevelObjectFormat ("fatalFormat", METALOG_LEVEL_FATAL) end
	function TestLoggingObject.testErrorFormat () testCaseForLevelObjectFormat ("errorFormat", METALOG_LEVEL_ERROR) end
	function TestLoggingObject.testWarnFormat  () testCaseForLevelObjectFormat ("warnFormat",  METALOG_LEVEL_WARN)  end
	function TestLoggingObject.testInfoFormat  () testCaseForLevelObjectFormat ("infoFormat",  METALOG_LEVEL_INFO)  end
	function TestLoggingObject.testDebugFormat () testCaseForLevelObjectFormat ("debugFormat", METALOG_LEVEL_DEBUG) end

	function TestLoggingObject.testFatalFormatChannel () testCaseForLevelObjectFormat ("fatalFormat", METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingObject.testErrorFormatChannel () testCaseForLevelObjectFormat ("errorFormat", METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingObject.testWarnFormatChannel  () testCaseForLevelObjectFormat ("warnFormat",  METALOG_LEVEL_WARN,  "test_channel") end
	function TestLoggingObject.testInfoFormatChannel  () testCaseForLevelObjectFormat ("infoFormat",  METALOG_LEVEL_INFO,  "test_channel") end
	function TestLoggingObject.testDebugFormatChannel () testCaseForLevelObjectFormat ("debugFormat", METALOG_LEVEL_DEBUG, "test_channel") end

	function TestLoggingObject.testFatalFormatInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelObjectFormat, "fatalFormat", METALOG_LEVEL_FATAL, NOT_A_STRING) end
	function TestLoggingObject.testErrorFormatInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelObjectFormat, "errorFormat", METALOG_LEVEL_ERROR, NOT_A_STRING) end
	function TestLoggingObject.testWarnFormatInvalidChannel  () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelObjectFormat, "warnFormat",  METALOG_LEVEL_WARN,  NOT_A_STRING) end
	function TestLoggingObject.testInfoFormatInvalidChannel  () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelObjectFormat, "infoFormat",  METALOG_LEVEL_INFO,  NOT_A_STRING) end
	function TestLoggingObject.testDebugFormatInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelObjectFormat, "debugFormat", METALOG_LEVEL_DEBUG, NOT_A_STRING) end

TestConsolePrinter = {}
	function TestConsolePrinter.setUp ()
		_G.__CONSOLE_PRINTER_NONE = false
		__MOCK_GMOD_RESET_CONVAR ("metalog_console_log_level")
	end

	function TestConsolePrinter.testDefaultIsPreserved ()
		local ml_console_printer = dofile ("lua/metalog_handlers/ml_console_printer.lua")
		local before = CreateConVar ("metalog_console_log_level"):GetString ()
		ml_console_printer.onMessage ("test:id", nil, METALOG_LEVEL_DEBUG, "test message")
		local after = CreateConVar ("metalog_console_log_level"):GetString ()

		lu.assertIs (after, before)
	end

	function TestConsolePrinter.testValidValueIsPreserved ()
		local ml_console_printer = dofile ("lua/metalog_handlers/ml_console_printer.lua")
		local default = CreateConVar ("metalog_console_log_level"):GetString ()
		CreateConVar ("metalog_console_log_level"):SetString ("warn")
		local before = CreateConVar ("metalog_console_log_level"):GetString ()
		lu.assertNotIs (before, default)

		ml_console_printer.onMessage ("test:id", nil, METALOG_LEVEL_DEBUG, "test message")
		local after = CreateConVar ("metalog_console_log_level"):GetString ()

		lu.assertIs (after, before)
	end

	function TestConsolePrinter.testInvalidValueIsResetToDefault ()
		local ml_console_printer = dofile ("lua/metalog_handlers/ml_console_printer.lua")
		local default = CreateConVar ("metalog_console_log_level"):GetString ()
		CreateConVar ("metalog_console_log_level"):SetString ("ThisIsInvalid")
		ml_console_printer.onMessage ("test:id", nil, METALOG_LEVEL_DEBUG, "test message")
		local after = CreateConVar ("metalog_console_log_level"):GetString ()

		lu.assertIs (after, default)
	end

	function TestConsolePrinter.testPrinting ()
		local ml_console_printer = dofile ("lua/metalog_handlers/ml_console_printer.lua")

		local old_print = print
		local received

		print = function (...) received = {...} end -- luacheck: ignore
		ml_console_printer.onMessage ("test:id", nil, METALOG_LEVEL_INFO, "test message")
		print = old_print -- luacheck: ignore

		lu.assertItemsEquals (received, {"test message"})
	end

	function TestConsolePrinter.tearDown ()
		_G.__CONSOLE_PRINTER_NONE = true
		__MOCK_GMOD_RESET_CONVAR ("metalog_console_log_level")
	end

os.exit (lu.LuaUnit.run())