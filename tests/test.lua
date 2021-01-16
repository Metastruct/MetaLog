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
		a, b = lu.private.prettystrPairs (a, b)
		return lu.fail (string.format ("expected: %s < %s", a, b))
	end
end

lu.assertIsTable (metalog)

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
		lu.assertEquals (metalog.getLevelName (METALOG_LEVEL_NONE),  "none")
		lu.assertEquals (metalog.getLevelName (METALOG_LEVEL_FATAL), "fatal")
		lu.assertEquals (metalog.getLevelName (METALOG_LEVEL_ERROR), "error")
		lu.assertEquals (metalog.getLevelName (METALOG_LEVEL_WARN),  "warn")
		lu.assertEquals (metalog.getLevelName (METALOG_LEVEL_INFO),  "info")
		lu.assertEquals (metalog.getLevelName (METALOG_LEVEL_DEBUG), "debug")
	end

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

	local function testCaseForLevelStatic (func, expectedLevel)
		local received = {}
		metalog.registerLoggingSink ("testing", function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end)

		local payload = { math.random(), math.random() }

		func ("test:id", nil, table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIsNil (received.channel)
		lu.assertIs (received.level, expectedLevel)
		for i = 1, 2 do
			lu.assertIs (received[i], payload[i])
		end
	end

	function TestLoggingStatic.testFatal ()
		return testCaseForLevelStatic (metalog.fatal, METALOG_LEVEL_FATAL)
	end
	function TestLoggingStatic.testError ()
		return testCaseForLevelStatic (metalog.error, METALOG_LEVEL_ERROR)
	end
	function TestLoggingStatic.testWarn ()
		return testCaseForLevelStatic (metalog.warn, METALOG_LEVEL_WARN)
	end
	function TestLoggingStatic.testInfo ()
		return testCaseForLevelStatic (metalog.info, METALOG_LEVEL_INFO)
	end
	function TestLoggingStatic.testDebug ()
		return testCaseForLevelStatic (metalog.debug, METALOG_LEVEL_DEBUG)
	end

	local function testCaseForLevelStaticFormat (func, expectedLevel)
		local received = {}
		metalog.registerLoggingSink ("testing", function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end)

		local payload = { math.random(), math.random(), "this one should be ignored" }

		func ("test:id", nil, "random numbers: %f %f", table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIsNil (received.channel)
		lu.assertIs (received.level, expectedLevel)
		lu.assertIs (received[1], string.format ("random numbers: %f %f", table.unpack (payload)))
		lu.assertIsNil (received[2])
		lu.assertIsNil (received[3])
	end

	function TestLoggingStatic.testFatalFormat ()
		return testCaseForLevelStaticFormat (metalog.fatalFormat, METALOG_LEVEL_FATAL)
	end
	function TestLoggingStatic.testErrorFormat ()
		return testCaseForLevelStaticFormat (metalog.errorFormat, METALOG_LEVEL_ERROR)
	end
	function TestLoggingStatic.testWarnFormat ()
		return testCaseForLevelStaticFormat (metalog.warnFormat, METALOG_LEVEL_WARN)
	end
	function TestLoggingStatic.testInfoFormat ()
		return testCaseForLevelStaticFormat (metalog.infoFormat, METALOG_LEVEL_INFO)
	end
	function TestLoggingStatic.testDebugFormat ()
		return testCaseForLevelStaticFormat (metalog.debugFormat, METALOG_LEVEL_DEBUG)
	end

TestLoggingObject = {}
	function TestLoggingObject.setUp ()
		metalog.unregisterLoggingSinks()
	end

	local function testCaseForLevelObject (method, expectedLevel)
		local received = {}
		metalog.registerLoggingSink ("testing", function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end)

		local payload = { math.random(), math.random() }

		local logger = metalog ("test:id")
		logger[method] (logger, table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIsNil (received.channel)
		lu.assertIs (received.level, expectedLevel)
		for i = 1, 2 do
			lu.assertIs (received[i], payload[i])
		end
	end

	function TestLoggingObject.testFatal ()
		return testCaseForLevelObject ("fatal", METALOG_LEVEL_FATAL)
	end
	function TestLoggingObject.testError ()
		return testCaseForLevelObject ("error", METALOG_LEVEL_ERROR)
	end
	function TestLoggingObject.testWarn ()
		return testCaseForLevelObject ("warn", METALOG_LEVEL_WARN)
	end
	function TestLoggingObject.testInfo ()
		return testCaseForLevelObject ("info", METALOG_LEVEL_INFO)
	end
	function TestLoggingObject.testDebug ()
		return testCaseForLevelObject ("debug", METALOG_LEVEL_DEBUG)
	end

	local function testCaseForLevelObjectFormat (method, expectedLevel)
		local received = {}
		metalog.registerLoggingSink ("testing", function (id, channel, level, ...)
			received = {id=id, channel=channel, level=level, ...}
		end)

		local payload = { math.random(), math.random(), "this one should be ignored" }

		local logger = metalog ("test:id")
		logger[method] (logger, "random numbers: %f %f", table.unpack (payload))

		lu.assertIs (received.id, "test:id")
		lu.assertIsNil (received.channel)
		lu.assertIs (received.level, expectedLevel)
		lu.assertIs (received[1], string.format ("random numbers: %f %f", table.unpack (payload)))
		lu.assertIsNil (received[2])
		lu.assertIsNil (received[3])
	end

	function TestLoggingObject.testFatalFormat ()
		return testCaseForLevelObjectFormat ("fatalFormat", METALOG_LEVEL_FATAL)
	end
	function TestLoggingObject.testErrorFormat ()
		return testCaseForLevelObjectFormat ("errorFormat", METALOG_LEVEL_ERROR)
	end
	function TestLoggingObject.testWarnFormat ()
		return testCaseForLevelObjectFormat ("warnFormat", METALOG_LEVEL_WARN)
	end
	function TestLoggingObject.testInfoFormat ()
		return testCaseForLevelObjectFormat ("infoFormat", METALOG_LEVEL_INFO)
	end
	function TestLoggingObject.testDebugFormat ()
		return testCaseForLevelObjectFormat ("debugFormat", METALOG_LEVEL_DEBUG)
	end

os.exit (lu.LuaUnit.run())