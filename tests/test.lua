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

	function TestSinkInterface.testGetLoggingSink ()
		local id = string.format ("Rnd%f", math.random())

		lu.assertIsNil (metalog.getLoggingSink (id..1))
		lu.assertIsNil (metalog.getLoggingSink (id..2))

		local sink1, sink2 = function()end, function()end
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

		local callback_A   = function (id) A = id end
		local callback_B   = function (id) B = id end
		local callback_err = function () error ("ERROR_ALWAYS") end

		metalog.registerLoggingSink ("testing1", callback_A)
		metalog.registerLoggingSink ("testing2", callback_err)
		metalog.registerLoggingSink ("testing3", callback_B)

		lu.assertIs (metalog.getLoggingSink ("testing1"), callback_A)
		lu.assertIs (metalog.getLoggingSink ("testing2"), callback_err)
		lu.assertIs (metalog.getLoggingSink ("testing3"), callback_B)

		metalog.debug ("example", nil, "An example log message.")

		lu.assertIs    (metalog.getLoggingSink ("testing1"), callback_A)
		lu.assertIsNil (metalog.getLoggingSink ("testing2"))
		lu.assertIs    (metalog.getLoggingSink ("testing3"), callback_B)

		lu.assertIs (A, "example")
		lu.assertIs (B, "example")
	end

TestLoggingStatic = {}
	function TestLoggingStatic.setUp ()
		metalog.unregisterLoggingSinks()
	end

	local function testCaseForLogStatic (testLevel, testChannel)
		local received
		metalog.registerLoggingSink ("testing", function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end)

		local payload = { math.random(), math.random() }

		metalog.log ("test:id", testChannel, testLevel, table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIs (received.channel, testChannel)
		lu.assertIs (received.level, testLevel)
		for i = 1, 2 do
			lu.assertIs (received[i], payload[i])
		end
	end

	function TestLoggingStatic.testLogFatal () return testCaseForLogStatic (METALOG_LEVEL_FATAL) end
	function TestLoggingStatic.testLogError () return testCaseForLogStatic (METALOG_LEVEL_ERROR) end
	function TestLoggingStatic.testLogWarn  () return testCaseForLogStatic (METALOG_LEVEL_WARN)  end
	function TestLoggingStatic.testLogInfo  () return testCaseForLogStatic (METALOG_LEVEL_INFO)  end
	function TestLoggingStatic.testLogDebug () return testCaseForLogStatic (METALOG_LEVEL_DEBUG) end

	function TestLoggingStatic.testLogFatalChannel () return testCaseForLogStatic (METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingStatic.testLogErrorChannel () return testCaseForLogStatic (METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingStatic.testLogWarnChannel  () return testCaseForLogStatic (METALOG_LEVEL_WARN , "test_channel") end
	function TestLoggingStatic.testLogInfoChannel  () return testCaseForLogStatic (METALOG_LEVEL_INFO , "test_channel") end
	function TestLoggingStatic.testLogDebugChannel () return testCaseForLogStatic (METALOG_LEVEL_DEBUG, "test_channel") end

	function TestLoggingStatic.testLogFatalInvalidLevel () lu.assertErrorMsgContains ('Invalid level', testCaseForLogStatic, NOT_A_STRING) end
	function TestLoggingStatic.testLogErrorInvalidLevel () lu.assertErrorMsgContains ('Invalid level', testCaseForLogStatic, NOT_A_STRING) end
	function TestLoggingStatic.testLogWarnInvalidLevel  () lu.assertErrorMsgContains ('Invalid level', testCaseForLogStatic, NOT_A_STRING) end
	function TestLoggingStatic.testLogInfoInvalidLevel  () lu.assertErrorMsgContains ('Invalid level', testCaseForLogStatic, NOT_A_STRING) end
	function TestLoggingStatic.testLogDebugInvalidLevel () lu.assertErrorMsgContains ('Invalid level', testCaseForLogStatic, NOT_A_STRING) end

	function TestLoggingStatic.testLogFatalInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLogStatic, METALOG_LEVEL_FATAL, NOT_A_STRING) end
	function TestLoggingStatic.testLogErrorInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLogStatic, METALOG_LEVEL_ERROR, NOT_A_STRING) end
	function TestLoggingStatic.testLogWarnInvalidChannel  () lu.assertErrorMsgContains ('expected optional string', testCaseForLogStatic, METALOG_LEVEL_WARN , NOT_A_STRING) end
	function TestLoggingStatic.testLogInfoInvalidChannel  () lu.assertErrorMsgContains ('expected optional string', testCaseForLogStatic, METALOG_LEVEL_INFO , NOT_A_STRING) end
	function TestLoggingStatic.testLogDebugInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLogStatic, METALOG_LEVEL_DEBUG, NOT_A_STRING) end

	local function testCaseForLevelStatic (func, expectedLevel, testChannel)
		local received
		metalog.registerLoggingSink ("testing", function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end)

		local payload = { math.random(), math.random() }

		func ("test:id", testChannel, table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIs (received.channel, testChannel)
		lu.assertIs (received.level, expectedLevel)
		for i = 1, 2 do
			lu.assertIs (received[i], payload[i])
		end
	end

	function TestLoggingStatic.testFatal () return testCaseForLevelStatic (metalog.fatal, METALOG_LEVEL_FATAL) end
	function TestLoggingStatic.testError () return testCaseForLevelStatic (metalog.error, METALOG_LEVEL_ERROR) end
	function TestLoggingStatic.testWarn  () return testCaseForLevelStatic (metalog.warn,  METALOG_LEVEL_WARN)  end
	function TestLoggingStatic.testInfo  () return testCaseForLevelStatic (metalog.info,  METALOG_LEVEL_INFO)  end
	function TestLoggingStatic.testDebug () return testCaseForLevelStatic (metalog.debug, METALOG_LEVEL_DEBUG) end

	function TestLoggingStatic.testFatalChannel () return testCaseForLevelStatic (metalog.fatal, METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingStatic.testErrorChannel () return testCaseForLevelStatic (metalog.error, METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingStatic.testWarnChannel  () return testCaseForLevelStatic (metalog.warn,  METALOG_LEVEL_WARN,  "test_channel") end
	function TestLoggingStatic.testInfoChannel  () return testCaseForLevelStatic (metalog.info,  METALOG_LEVEL_INFO,  "test_channel") end
	function TestLoggingStatic.testDebugChannel () return testCaseForLevelStatic (metalog.debug, METALOG_LEVEL_DEBUG, "test_channel") end

	function TestLoggingStatic.testFatalInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelStatic, metalog.fatal, METALOG_LEVEL_FATAL, NOT_A_STRING) end
	function TestLoggingStatic.testErrorInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelStatic, metalog.error, METALOG_LEVEL_ERROR, NOT_A_STRING) end
	function TestLoggingStatic.testWarnInvalidChannel  () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelStatic, metalog.warn,  METALOG_LEVEL_WARN,  NOT_A_STRING) end
	function TestLoggingStatic.testInfoInvalidChannel  () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelStatic, metalog.info,  METALOG_LEVEL_INFO,  NOT_A_STRING) end
	function TestLoggingStatic.testDebugInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelStatic, metalog.debug, METALOG_LEVEL_DEBUG, NOT_A_STRING) end

	local function testCaseForLogStaticFormat (testLevel, testChannel)
		local received
		metalog.registerLoggingSink ("testing", function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end)

		local payload = { math.random(), math.random(), "this one should be ignored" }

		metalog.logFormat ("test:id", testChannel, testLevel, "random numbers: %f %f", table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIs (received.channel, testChannel)
		lu.assertIs (received.level, testLevel)
		lu.assertIs (received[1], string.format ("random numbers: %f %f", table.unpack (payload)))
		lu.assertIsNil (received[2])
		lu.assertIsNil (received[3])
	end

	function TestLoggingStatic.testLogFatalFormat () return testCaseForLogStaticFormat (METALOG_LEVEL_FATAL) end
	function TestLoggingStatic.testLogErrorFormat () return testCaseForLogStaticFormat (METALOG_LEVEL_ERROR) end
	function TestLoggingStatic.testLogWarnFormat  () return testCaseForLogStaticFormat (METALOG_LEVEL_WARN)  end
	function TestLoggingStatic.testLogInfoFormat  () return testCaseForLogStaticFormat (METALOG_LEVEL_INFO)  end
	function TestLoggingStatic.testLogDebugFormat () return testCaseForLogStaticFormat (METALOG_LEVEL_DEBUG) end

	function TestLoggingStatic.testLogFatalFormatChannel () return testCaseForLogStaticFormat (METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingStatic.testLogErrorFormatChannel () return testCaseForLogStaticFormat (METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingStatic.testLogWarnFormatChannel  () return testCaseForLogStaticFormat (METALOG_LEVEL_WARN,  "test_channel") end
	function TestLoggingStatic.testLogInfoFormatChannel  () return testCaseForLogStaticFormat (METALOG_LEVEL_INFO,  "test_channel") end
	function TestLoggingStatic.testLogDebugFormatChannel () return testCaseForLogStaticFormat (METALOG_LEVEL_DEBUG, "test_channel") end

	function TestLoggingStatic.testLogFatalFormatInvalidLevel () lu.assertErrorMsgContains ('Invalid level', testCaseForLogStaticFormat, NOT_A_STRING) end
	function TestLoggingStatic.testLogErrorFormatInvalidLevel () lu.assertErrorMsgContains ('Invalid level', testCaseForLogStaticFormat, NOT_A_STRING) end
	function TestLoggingStatic.testLogWarnFormatInvalidLevel  () lu.assertErrorMsgContains ('Invalid level', testCaseForLogStaticFormat, NOT_A_STRING) end
	function TestLoggingStatic.testLogInfoFormatInvalidLevel  () lu.assertErrorMsgContains ('Invalid level', testCaseForLogStaticFormat, NOT_A_STRING) end
	function TestLoggingStatic.testLogDebugFormatInvalidLevel () lu.assertErrorMsgContains ('Invalid level', testCaseForLogStaticFormat, NOT_A_STRING) end

	function TestLoggingStatic.testLogFatalFormatInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLogStaticFormat, METALOG_LEVEL_FATAL, NOT_A_STRING) end
	function TestLoggingStatic.testLogErrorFormatInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLogStaticFormat, METALOG_LEVEL_ERROR, NOT_A_STRING) end
	function TestLoggingStatic.testLogWarnFormatInvalidChannel  () lu.assertErrorMsgContains ('expected optional string', testCaseForLogStaticFormat, METALOG_LEVEL_WARN,  NOT_A_STRING) end
	function TestLoggingStatic.testLogInfoFormatInvalidChannel  () lu.assertErrorMsgContains ('expected optional string', testCaseForLogStaticFormat, METALOG_LEVEL_INFO,  NOT_A_STRING) end
	function TestLoggingStatic.testLogDebugFormatInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLogStaticFormat, METALOG_LEVEL_DEBUG, NOT_A_STRING) end

	local function testCaseForLevelStaticFormat (func, expectedLevel, testChannel)
		local received
		metalog.registerLoggingSink ("testing", function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end)

		local payload = { math.random(), math.random(), "this one should be ignored" }

		func ("test:id", testChannel, "random numbers: %f %f", table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIs (received.channel, testChannel)
		lu.assertIs (received.level, expectedLevel)
		lu.assertIs (received[1], string.format ("random numbers: %f %f", table.unpack (payload)))
		lu.assertIsNil (received[2])
		lu.assertIsNil (received[3])
	end

	function TestLoggingStatic.testFatalFormat () return testCaseForLevelStaticFormat (metalog.fatalFormat, METALOG_LEVEL_FATAL) end
	function TestLoggingStatic.testErrorFormat () return testCaseForLevelStaticFormat (metalog.errorFormat, METALOG_LEVEL_ERROR) end
	function TestLoggingStatic.testWarnFormat  () return testCaseForLevelStaticFormat (metalog.warnFormat,  METALOG_LEVEL_WARN)  end
	function TestLoggingStatic.testInfoFormat  () return testCaseForLevelStaticFormat (metalog.infoFormat,  METALOG_LEVEL_INFO)  end
	function TestLoggingStatic.testDebugFormat () return testCaseForLevelStaticFormat (metalog.debugFormat, METALOG_LEVEL_DEBUG) end

	function TestLoggingStatic.testFatalFormatChannel () return testCaseForLevelStaticFormat (metalog.fatalFormat, METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingStatic.testErrorFormatChannel () return testCaseForLevelStaticFormat (metalog.errorFormat, METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingStatic.testWarnFormatChannel  () return testCaseForLevelStaticFormat (metalog.warnFormat,  METALOG_LEVEL_WARN,  "test_channel") end
	function TestLoggingStatic.testInfoFormatChannel  () return testCaseForLevelStaticFormat (metalog.infoFormat,  METALOG_LEVEL_INFO,  "test_channel") end
	function TestLoggingStatic.testDebugFormatChannel () return testCaseForLevelStaticFormat (metalog.debugFormat, METALOG_LEVEL_DEBUG, "test_channel") end

	function TestLoggingStatic.testFatalFormatInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelStaticFormat, metalog.fatalFormat, METALOG_LEVEL_FATAL, NOT_A_STRING) end
	function TestLoggingStatic.testErrorFormatInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelStaticFormat, metalog.errorFormat, METALOG_LEVEL_ERROR, NOT_A_STRING) end
	function TestLoggingStatic.testWarnFormatInvalidChannel  () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelStaticFormat, metalog.warnFormat,  METALOG_LEVEL_WARN,  NOT_A_STRING) end
	function TestLoggingStatic.testInfoFormatInvalidChannel  () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelStaticFormat, metalog.infoFormat,  METALOG_LEVEL_INFO,  NOT_A_STRING) end
	function TestLoggingStatic.testDebugFormatInvalidChannel () lu.assertErrorMsgContains ('expected optional string', testCaseForLevelStaticFormat, metalog.debugFormat, METALOG_LEVEL_DEBUG, NOT_A_STRING) end

TestLoggingObject = {}
	function TestLoggingObject.setUp ()
		metalog.unregisterLoggingSinks()
	end

	local function testCaseForLevelObject (method, expectedLevel, testChannel)
		local received
		metalog.registerLoggingSink ("testing", function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end)

		local payload = { math.random(), math.random() }

		local logger = metalog ("test:id", testChannel)
		logger[method] (logger, table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIs (received.channel, testChannel)
		lu.assertIs (received.level, expectedLevel)
		for i = 1, 2 do
			lu.assertIs (received[i], payload[i])
		end
	end

	function TestLoggingObject.testFatal () return testCaseForLevelObject ("fatal", METALOG_LEVEL_FATAL) end
	function TestLoggingObject.testError () return testCaseForLevelObject ("error", METALOG_LEVEL_ERROR) end
	function TestLoggingObject.testWarn  () return testCaseForLevelObject ("warn",  METALOG_LEVEL_WARN)  end
	function TestLoggingObject.testInfo  () return testCaseForLevelObject ("info",  METALOG_LEVEL_INFO)  end
	function TestLoggingObject.testDebug () return testCaseForLevelObject ("debug", METALOG_LEVEL_DEBUG) end

	function TestLoggingObject.testFatalChannel () return testCaseForLevelObject ("fatal", METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingObject.testErrorChannel () return testCaseForLevelObject ("error", METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingObject.testWarnChannel  () return testCaseForLevelObject ("warn",  METALOG_LEVEL_WARN,  "test_channel") end
	function TestLoggingObject.testInfoChannel  () return testCaseForLevelObject ("info",  METALOG_LEVEL_INFO,  "test_channel") end
	function TestLoggingObject.testDebugChannel () return testCaseForLevelObject ("debug", METALOG_LEVEL_DEBUG, "test_channel") end

	function TestLoggingObject.testInvalidChannel () lu.assertErrorMsgContains ('expected optional string', metalog, "test:id", NOT_A_STRING) end

	local function testCaseForLevelObjectFormat (method, expectedLevel, testChannel)
		local received
		metalog.registerLoggingSink ("testing", function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end)

		local payload = { math.random(), math.random(), "this one should be ignored" }

		local logger = metalog ("test:id", testChannel)
		logger[method] (logger, "random numbers: %f %f", table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIs (received.channel, testChannel)
		lu.assertIs (received.level, expectedLevel)
		lu.assertIs (received[1], string.format ("random numbers: %f %f", table.unpack (payload)))
		lu.assertIsNil (received[2])
		lu.assertIsNil (received[3])
	end

	function TestLoggingObject.testFatalFormat () return testCaseForLevelObjectFormat ("fatalFormat", METALOG_LEVEL_FATAL) end
	function TestLoggingObject.testErrorFormat () return testCaseForLevelObjectFormat ("errorFormat", METALOG_LEVEL_ERROR) end
	function TestLoggingObject.testWarnFormat  () return testCaseForLevelObjectFormat ("warnFormat",  METALOG_LEVEL_WARN)  end
	function TestLoggingObject.testInfoFormat  () return testCaseForLevelObjectFormat ("infoFormat",  METALOG_LEVEL_INFO)  end
	function TestLoggingObject.testDebugFormat () return testCaseForLevelObjectFormat ("debugFormat", METALOG_LEVEL_DEBUG) end

	function TestLoggingObject.testFatalFormatChannel () return testCaseForLevelObjectFormat ("fatalFormat", METALOG_LEVEL_FATAL, "test_channel") end
	function TestLoggingObject.testErrorFormatChannel () return testCaseForLevelObjectFormat ("errorFormat", METALOG_LEVEL_ERROR, "test_channel") end
	function TestLoggingObject.testWarnFormatChannel  () return testCaseForLevelObjectFormat ("warnFormat",  METALOG_LEVEL_WARN,  "test_channel") end
	function TestLoggingObject.testInfoFormatChannel  () return testCaseForLevelObjectFormat ("infoFormat",  METALOG_LEVEL_INFO,  "test_channel") end
	function TestLoggingObject.testDebugFormatChannel () return testCaseForLevelObjectFormat ("debugFormat", METALOG_LEVEL_DEBUG, "test_channel") end

TestConsolePrinter = {}
	function TestConsolePrinter.setUp ()
		_G.__CONSOLE_PRINTER_NONE = false
		__MOCK_GMOD_RESET_CONVAR ("metalog_console_log_level")
	end

	function TestConsolePrinter.testDefaultIsPreserved ()
		local ml_console_printer = dofile ("lua/metalog_handlers/ml_console_printer.lua")
		local before = CreateConVar ("metalog_console_log_level"):GetString ()
		ml_console_printer ("test:id", nil, METALOG_LEVEL_DEBUG, "test message")
		local after = CreateConVar ("metalog_console_log_level"):GetString ()

		lu.assertIs (after, before)
	end

	function TestConsolePrinter.testValidValueIsPreserved ()
		local ml_console_printer = dofile ("lua/metalog_handlers/ml_console_printer.lua")
		local default = CreateConVar ("metalog_console_log_level"):GetString ()
		CreateConVar ("metalog_console_log_level"):SetString ("warn")
		local before = CreateConVar ("metalog_console_log_level"):GetString ()
		lu.assertNotIs (before, default)

		ml_console_printer ("test:id", nil, METALOG_LEVEL_DEBUG, "test message")
		local after = CreateConVar ("metalog_console_log_level"):GetString ()

		lu.assertIs (after, before)
	end

	function TestConsolePrinter.testInvalidValueIsResetToDefault ()
		local ml_console_printer = dofile ("lua/metalog_handlers/ml_console_printer.lua")
		local default = CreateConVar ("metalog_console_log_level"):GetString ()
		CreateConVar ("metalog_console_log_level"):SetString ("ThisIsInvalid")
		ml_console_printer ("test:id", nil, METALOG_LEVEL_DEBUG, "test message")
		local after = CreateConVar ("metalog_console_log_level"):GetString ()

		lu.assertIs (after, default)
	end

	function TestConsolePrinter.testPrinting ()
		local ml_console_printer = dofile ("lua/metalog_handlers/ml_console_printer.lua")

		local old_print = print
		local received

		print = function (...) received = {...} end -- luacheck: ignore
		ml_console_printer ("test:id", nil, METALOG_LEVEL_INFO, "test message")
		print = old_print -- luacheck: ignore

		lu.assertItemsEquals (received, {"test message"})
	end

	function TestConsolePrinter.tearDown ()
		_G.__CONSOLE_PRINTER_NONE = true
		__MOCK_GMOD_RESET_CONVAR ("metalog_console_log_level")
	end

os.exit (lu.LuaUnit.run())