class_name SerializationUtil


## Replaces any occurance of a serialized GDScript in a string with nothing.
static func strip_scripts(data: String) -> String:
	var regex := RegEx.create_from_string(r".*Object\(GDScript.*\)\n")
	return regex.sub(data, String(), true)
 
