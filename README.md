# MetaLog
An extendable logger for Garry's Mod scripts.

## (!!) Important Information
**(/!\\) MetaLog is a work-in-progress script and the interface and usage information below can still change in the future.**  
Therefore, usage is not yet recommended or you risk that future incompatible changes will break your scripts and you will have to update to accomodate for them.

## End-User Usage / Project Scope / Intended Use:
How to select which log levels to display, and where they end up appearing, will depend a lot on how MetaLog is used.  
MetaLog is purely intended to be a library or framework, the backbone providing the infrastructure for flows of log messages.

By default, MetaLog simply prints log messages to the console. You can change the log level cut-off using the `metalog_console_log_level` console variable.

The default logger can be turned off or even removed and replaced with a more suited log display or handler. This should allow server/community owners to use MetaLog server-wide and direct the logging to wherever they think would me most helpful.  
Examples include adding an additional Discord logging sink to send log messages to one or more Discord channels or to implement silly things such as making an NPC say all `info` log messages using text-to-speech.

The possibilities are endless, really.
## Usage

1. Require metalog in your script.
2. Create a logger object by calling `metalog` with the name of your script and optionally the name of a channel.
3. Use any of the following methods on the logger object:
	- fatal (only logs that concern errors that cause a full-scale breakage of scripts)
	- error (all other errors that indicate unintended behavior)
	- warn (warnings that are not yet quite errors but deserve some attention)
	- info (purely informative messages)
	- debug (verbose messages of mostly developer value, if it's noisy, it probably belongs here)

## Log Levels

The log levels' identifiers are:
- METALOG_LEVEL_FATAL
- METALOG_LEVEL_ERROR
- METALOG_LEVEL_WARN
- METALOG_LEVEL_INFO
- METALOG_LEVEL_DEBUG

and can be used in logging sinks to interpret the log level of a message or implement level filters.

## Logging Sinks

MetaLog relays all log messages, regardless of log level, to all registered logging sinks.
A logging sink is basically a function callback with the signature
```Lua
function (id, channel, level, message, ...)
```
- `id` is the id as passed to the `metalog` constructor
- `channel` is the channel as passed to the `metalog` constructor
- `level` is a numeric identifier representing the log level.
- `message` is a string potentially containing `string.format`-compatible placeholders.
- `(...)` can optionally contain more values. These do not have a standard format and will most likely contain additional values to be inserted into the previous `message` string in place of the placeholders.

When implementing a logging sink, it is important to make sure that `message`s containing `string.format`-compatible placeholders are to be interpreted in a way that respects the placeholders.
That means, if message contains placeholders such as `%s` or `%02d` or `%.5f` then the caller of the log function expects you to fill them in using the values supplied by `(...)`.  
This is explicitly part of the API design to enforce certain limits for the users (callers) of the logger (i.e. the scripts that call `:info()`, `:warn()` etc.). If they wish to literally print the string `%d`, they need to escape it as `%%d`.

MetaLog currently ships with one default logging sink, the console printer.
You can find it in `metalog_handlers/ml_console_printer.lua`. It contains a relatively trivial sink that prints formatted log messages to the console using `MsgC` and `print` calls. 

## Example

```Lua
require ("metalog")

local logger = metalog ("myScriptName")
logger:info ("This is a piece of information.")
logger:error ("Something broke, this is not good.")

local loggerA = metalog ("myScriptWithChannels", "categoryA")  loggerA:debug ("The secret is %d.", 123)
```