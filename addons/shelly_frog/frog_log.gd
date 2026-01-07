@tool
class_name FrogLog
extends RefCounted
## Wrapper class for logging info in a more
## streamlined fashion.

enum LogLevel {
	MESSAGE = 1,
	WARNING = 1 << 1,
	ERROR = 1 << 2,
	DEBUG = 1 << 4,
}

const ENABLED_LOGS: Array[LogLevel] = [
	LogLevel.MESSAGE,
	LogLevel.WARNING,
	LogLevel.ERROR,
	#LogLevel.DEBUG,
]

const COLORS: Dictionary[LogLevel, String] = {
	LogLevel.MESSAGE: "GRAY",
	LogLevel.WARNING: "SANDY_BROWN",
	LogLevel.ERROR: "LIGHT_CORAL",
	LogLevel.DEBUG: "DARK_SLATE_GRAY",
}


## Logs a message at [constant LogLevel.MESSAGE] level.
static func message(content, title := String()):
	_log(LogLevel.MESSAGE, title, content)


## Logs a message at [constant LogLevel.WARNING] level.
static func warning(content, title := String()):
	_log(LogLevel.WARNING, title, content)


## Logs a message at [constant LogLevel.ERROR] level.
static func error(content, title := String()):
	_log(LogLevel.ERROR, title, content)


## Logs a message at [constant LogLevel.DEBUG] level.
static func debug(content, title := String()):
	_log(LogLevel.DEBUG, title, content)


static func _log(level: LogLevel, title: String, content):
	if not ENABLED_LOGS.has(level):
		return

	var beginning := "[color=%s][%s%s] " % [
		COLORS[level],
		LogLevel.find_key(level),
		String() if title.is_empty() else (" (%s)" % title),
	]
	print_rich(beginning + content + "[/color]")
