@tool
extends RefCounted

const REGION_NAME_KEY: String = "name"


## Creates a dictionary containing the values of a GDX .atlas file.
## The structure looks like this:
## [codeblock lang=text]
## {
##     "page_file.png": [
##         {
##             "name": "region_name",
##             "bounds": Rect2,
##             "offsets": Rect2,
##             "index": int
##         },
##         {
##             ...
##         },
##     ]
## }
## [/codeblock]
static func parse(file: FileAccess) -> Dictionary:
	var pages := Dictionary()
	var property := PackedStringArray()
	# The max amount of values is 5.
	property.resize(5)

	var region_entries: Dictionary[String, Callable] = {
		"bounds": (func(property: PackedStringArray):
			return Rect2(
						property[1].to_int(),
						property[2].to_int(),
						property[3].to_int(),
						property[4].to_int()
				)
			),
		"offsets": (func(property: PackedStringArray):
			return Rect2(
						property[1].to_int(),
						property[2].to_int(),
						property[3].to_int(),
						property[4].to_int()
				)
			),
		"index": (func(property: PackedStringArray):
			return property[1].to_int()
			),
	}

	var file_length: int = file.get_length()
	var line := String()
	# Ignore empty lines at the start.
	while file.get_position() < file_length and line.is_empty():
		line = file.get_line().strip_edges()

	# Ignore header.
	while file.get_position() < file_length:
		if line.is_empty():
			break
		if _parse_property(property, line) == 0:
			break
		line = file.get_line().strip_edges()

	var page_name: String
	const MAX_INT: int = 9223372036854775807
	while file.get_position() < file_length:
		if line.is_empty():
			# Empty lines indicate a new page.
			pages[page_name].sort_custom(
					func(a, b):
						var a_index: int = a.get("index", MAX_INT)
						var b_index: int = a.get("index", MAX_INT)
						return a_index < b_index
			)
			page_name = String()
			line = file.get_line().strip_edges()

		if page_name.is_empty():
			page_name = line
			pages[page_name] = []
			while true:
				# Loop until a name pops up again (0 values).
				line = file.get_line().strip_edges()
				if _parse_property(property, line) == 0:
					break
		else:
			var region: Dictionary = {
				REGION_NAME_KEY: line
			}
			while true:
				line = file.get_line().strip_edges()
				var value_count: int = _parse_property(property, line)
				if value_count == 0:
					break
				var key: String = property[0]
				var parser: Callable = region_entries.get(key, Callable())
				if parser.is_valid():
					region[key] = parser.call(property)
			pages[page_name].push_back(region)

	return pages


## Tries to parse the atlas line [param line] into [param output]
## and returns the number of values.
static func _parse_property(output: PackedStringArray, line: String) -> int:
	if line.is_empty():
		return 0

	var colon_index: int = line.find(':')
	if colon_index == -1:
		return 0

	# property name.
	output[0] = line.left(colon_index).strip_edges()

	var last_index: int = colon_index + 1
	var comma_index: int
	for i in range(1, 5):
		comma_index = line.find(',', last_index)
		if comma_index == -1:
			output[i] = line.substr(last_index).strip_edges()
			return i
		output[i] = line.substr(last_index, comma_index - last_index)
		last_index = comma_index + 1
	return 4
