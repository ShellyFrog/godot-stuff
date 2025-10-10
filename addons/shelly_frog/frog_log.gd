@tool
class_name FrogLog
extends RefCounted
## Wrapper class for logging info in a more
## streamlined fashion.

enum LogLevel {
	MESSAGE,
	WARNING,
	ERROR
}

const COLORS: Dictionary[LogLevel, String] = {
	LogLevel.MESSAGE: "GRAY",
	LogLevel.WARNING: "SANDY_BROWN",
	LogLevel.ERROR: "LIGHT_CORAL",
}


## Logs a message at [constant LogLevel.MESSAGE] level.
static func message(content, title: String = ""):
	_log(LogLevel.MESSAGE, title, content)


## Logs a message at [constant LogLevel.WARNING] level.
static func warning(content, title: String = ""):
	_log(LogLevel.WARNING, title, content)


## Logs a message at [constant LogLevel.ERROR] level.
static func error(content, title: String = ""):
	_log(LogLevel.ERROR, title, content)


static func _log(level: LogLevel, title: String, content):
	var beginning := "[color=%s][%s%s] " % [
		COLORS[level],
		LogLevel.keys()[level],
		"" if title.is_empty() else (" (%s)" % title),
	]
	print_rich(beginning + content + "[/color]")
