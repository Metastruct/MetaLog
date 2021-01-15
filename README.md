# MetaLog
An extendable logging framework for Garry's Mod.

## (!!) Important Information
**(/!\\) MetaLog is a work-in-progress script and the interface and usage information below can still change in the future.**  
Therefore, usage is not yet recommended or you risk that future incompatible changes will break your scripts and you will have to update to accomodate for them.

You can see the **v1.0 milestone** [here](https://github.com/Metastruct/MetaLog/milestone/1) and it lists the remaining known issues and TODOs before MetaLog can be considered a "finished" specification.

## End-User Usage / Project Scope / Intended Use:
How to select which log levels to display, and where they end up appearing, will depend a lot on how MetaLog is used.  
MetaLog is purely intended to be a library or framework, the backbone providing the infrastructure for flows of log messages.

By default, MetaLog simply prints log messages to the console. You can change the log level cut-off using the `metalog_console_log_level` console variable.

The default logger can be turned off or even removed and replaced with a more suited log display or handler. This should allow server/community owners to use MetaLog server-wide and direct the logging to wherever they think would be most helpful.  
Examples include adding an additional Discord logging sink to send log messages to one or more Discord channels or to implement silly things such as making an NPC say all `info` log messages using text-to-speech.

The possibilities are endless, really.
## Usage

1. Require metalog in your script.
	```Lua
	require ("metalog")
	```
2. Create a logger object by calling `metalog` with the name of your script (`id`) and optionally the name of a `channel`.
	```Lua
	-- example
	logger = metalog ("myScript", "channelX")
	```
3. Use any of the following methods on the logger object:
	- `fatal` (only logs that concern errors that cause a full-scale breakage of scripts)
	- `error` (all other errors that indicate unintended behavior)
	- `warn` (warnings that are not yet quite errors but deserve some attention)
	- `info` (purely informative messages)
	- `debug` (verbose messages of mostly developer value, if it's noisy, it probably belongs here)

	```Lua
	-- example
	logger:warn ("The the florbish is grommicking!")
	```

All methods (`fatal`, `error` etc.) are also available with a `Format` suffix (i.e. `fatalFormat`, `errorFormat`, ...) which are equivalent to their non-Format variants but the arguments are first passed through `string.format`.

That means:
```Lua
logger:infoFormat ("Pi is roughly %f", math.pi)
```
is equivalent to
```Lua
logger:info (string.format ("Pi is roughly %f", math.pi))
```
both will print "`Pi is roughly 3.141593`".
## Alternative Usage

Instead of the above described standard way of using MetaLog, you can also call static methods without first creating a logger object. All the same methods exist as static methods on the global `metalog`, but you need to pass the `id` and `channel` before passing the rest of the parameters.

That means:
```Lua
local logger = metalog ("myScript", "A")
logger:infoFormat ("Pi is roughly %f", math.pi)
logger:warn ("Pi is exactly 3")
```
is equivalent to:
```Lua
metalog.infoFormat ("myScript", "A", "Pi is roughly %f", math.pi)
metalog.warn ("myScript", "A", "Pi is exactly 3")
```

Usually the former way of using MetaLog is preferred because it produces cleaner code. However, if you only need a single log call in a specific file, it might not make a lot of sense to create an object first. But this is your decision, really.

## Log Levels

The log levels' identifiers are:
- `METALOG_LEVEL_FATAL`
- `METALOG_LEVEL_ERROR`
- `METALOG_LEVEL_WARN`
- `METALOG_LEVEL_INFO`
- `METALOG_LEVEL_DEBUG`

and can be used in logging sinks to interpret the log level of a message or implement level filters. They are currently powers of two (so no two levels can be combined using AND to produce non-zero) and noisier levels are bigger in value than less noisy levels (i.e. `METALOG_LEVEL_DEBUG` > `METALOG_LEVEL_WARN`).  
Please try not to hard-code the actual values in your codes but rely on these identifiers so that in the event of future changes, levels can be rearranged or otherwise modified without breakages.

## Logging Sinks

MetaLog relays all log messages, regardless of log level, to all registered logging sinks.
A logging sink is basically a function callback with the signature
```Lua
function (id, channel, level, ...)
```
- `id` is the id as passed to the `metalog` constructor
- `channel` is the channel as passed to the `metalog` constructor
- `level` is a numeric identifier representing the log level.
- `(...)` contains the values that make up the log message. These do not have a standard format and will most likely contain strings, numbers and other Lua types. Literally anything goes here. It is the sink's job to format these in a desireable way.

When implementing a logging sink, you can implement filters based on the `id`, `channel` or `level`.
The levels (`METALOG_LEVEL_FATAL` etc.) can be combined using bitwise operations to form a bitmask to check against, if so desired (no two level identifiers combined with AND result in something non-zero). This is purely a practical issue, though, and you can implement your filters, if any, however you desire.

MetaLog currently ships with one default logging sink, the console printer.
You can find it in `metalog_handlers/ml_console_printer.lua`. It contains a relatively trivial sink that prints formatted log messages to the console using `MsgC` and `print` calls.

The default sink's logging filter simply offers a convar-controllable log level threshold that does a greater-than-or-equal check against incoming log messages.

## Example

```Lua
require ("metalog")

local logger = metalog ("myScriptName")
logger:info ("This is a piece of information.")
logger:warn ("Entity(0) is, and will forever be, ", Entity (0))
logger:error ("Something broke! This is not good.")

local loggerA = metalog ("myScriptWithChannels", "categoryA")
loggerA:debug ("The secret is %d.", 123)
```
