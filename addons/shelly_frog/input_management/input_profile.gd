@icon("./_icons/InputProfile.svg")
class_name InputProfile
extends Resource
## Resource containing events and optional settings for
## input remapping.

## Emitted when [member name] has changed.
signal name_changed(old_name: StringName, new_name: StringName)

enum EventType {
	KEY,
	MOUSE,
	JOY_BUTTON,
	JOY_MOTION
}

const TITLE = "name"
const TYPE = "type"

const KEYCODE = "keycode"
const KEYCODE_PHYSICAL = "physical_keycode"
const KEY_LABEL = "key_label"

const BUTTON_INDEX = "button_index"

const AXIS = "axis"
const AXIS_VALUE = "axis_value"

const BINDS_GROUP = "binds"
const SETTINGS_GROUP = "settings"

## The name of this profile.
var name: StringName:
	set(value):
		if name == value:
			return
		var previous_name = name;
		name = value;
		name_changed.emit(previous_name, value);

## A dictionary of optional settings.
var settings: Dictionary[StringName, Variant]

# No type for the array because nested typed collections
# aren't supported yet.
var _remap: Dictionary[StringName, Array]


## Attempts to read [param file] as JSON and returns an input profile
## containing the data, otherwise [code]NULL[/code].
static func try_create_from_file(file: FileAccess) -> InputProfile:
	var parsed = JSON.parse_string(file.get_as_text())
	
	if parsed is not Dictionary:
		FrogLog.error("Parsed input profile JSON at %s was not a dictionary." % file.get_path_absolute())
		return null
	
	var profile := InputProfile.new()
	profile._parse_json(parsed)
	return profile


## Returns the input events for [param action].
## [br]
## [b]Note:[/b] This may return an empty array.
func get_action_events(action: StringName) -> Array[InputEvent]:
	# Doing this strange pattern because Dictionary.get(action, [])
	# results in an array type error.
	if _remap.has(action):
		return _remap[action]
	return []


## Sets all input events for [param action].
## [br]
## [b]Note:[/b] This overwrites any existing events.
func set_action_events(action: StringName, events: Array[InputEvent]):
	_remap[action] = events
	emit_changed()


## Adds a single event for [param action] or creates a new
## array of input events for [param action] if it did not exist.
func add_event_to_action(action: StringName, input_event: InputEvent):
	if not input_event:
		return

	if _remap.has(action):
		var events = _remap[action]
		if not events.has(input_event):
			events.append(input_event)
	else:
		_remap[action] = [input_event]

	emit_changed()


## Removes a single event from [param action] if it exists.
func remove_event_from_action(action: StringName, input_event: InputEvent):
	var events: Array = _remap.get(action, null)
	if events:
		events.erase(input_event)
		if events.is_empty():
			_remap.erase(action)

	emit_changed()


## Returns the value for a setting with the key [param key]
## if it exists, otherwise [code]null[/code].
func get_setting(key: StringName) -> Variant:
	return settings.get(key, null)


## Adds or overwrites the value for a setting with key [param key].
func add_or_set_setting(key: StringName, value):
	settings[key] = value


## Writes the profile's content to [param file] as JSON.
func write(file: FileAccess):
	file.store_string(_get_json())


func _get_json() -> String:
	var json_dictionary: Dictionary[StringName, Variant]
	var binds_dictionary: Dictionary[StringName, Variant]

	for action in _remap.keys():
		var action_remap: Array = _remap[action]
		var input_events: Array[Dictionary]

		for event in action_remap:
			var event_data: Dictionary
			if event is InputEventKey:
				event_data[TYPE] = EventType.KEY
				event_data[KEYCODE] = event.keycode
				event_data[KEYCODE_PHYSICAL] = event.physical_keycode
				event_data[KEY_LABEL] = event.key_label
			elif event is InputEventMouseButton:
				event_data[TYPE] = EventType.MOUSE
				event_data[BUTTON_INDEX] = event.button_index
			elif event is InputEventJoypadButton:
				event_data[TYPE] = EventType.JOY_BUTTON
				event_data[BUTTON_INDEX] = event.button_index
			elif event is InputEventJoypadMotion:
				event_data[TYPE] = EventType.JOY_MOTION
				event_data[AXIS] = event.axis
				event_data[AXIS_VALUE] = event.axis_value

			input_events.append(event_data)

		binds_dictionary[action] = input_events

	json_dictionary[TITLE] = name
	json_dictionary[SETTINGS_GROUP] = settings
	json_dictionary[BINDS_GROUP] = binds_dictionary

	return JSON.stringify(json_dictionary, "\t", false);


func _parse_json(dictionary: Dictionary):
	_remap.clear();

	for key in dictionary.keys():
		var value = dictionary[key]

		if key == TITLE and value is String:
			if value.is_empty():
				printerr("Parsing input profile failed: Name cannot be empty.")
				return false
			else:
				name = value
			continue

		if value is not Dictionary:
			continue

		if key == BINDS_GROUP:
			for action in value.keys():
				if not InputMap.has_action(action):
					continue

				var event_list = value[action]
				if event_list is not Array:
					continue

				var remaps: Array[InputEvent]
				for event_data in event_list:
					if not event_data.has(TYPE):
						continue

					var event_type := event_data[TYPE] as EventType
					var event: InputEvent

					match event_type:
						EventType.KEY:
							if not (event_data.has(KEYCODE) \
								and event_data.has(KEYCODE_PHYSICAL) \
								and event_data.has(KEY_LABEL)):
								continue

							event = InputEventKey.new()
							event.keycode = event_data[KEYCODE]
							event.physical_keycode = event_data[KEYCODE_PHYSICAL]
							event.key_label = event_data[KEY_LABEL]

						EventType.MOUSE:
							if not event_data.has(BUTTON_INDEX):
								continue

							event = InputEventMouseButton.new()
							event.button_index = event_data[BUTTON_INDEX]

						EventType.JOY_BUTTON:
							if not event_data.has(BUTTON_INDEX):
								continue

							event = InputEventJoypadButton.new()
							event.button_index = event_data[BUTTON_INDEX]

						EventType.JOY_MOTION:
							if not (event_data.has(AXIS) \
								and event_data.has(AXIS_VALUE)):
								continue

							event = InputEventJoypadMotion.new()
							event.axis = event_data[AXIS]
							event.axis_value = event_data[AXIS_VALUE]

						_:
							continue

					remaps.append(event)

				if not remaps.is_empty():
					set_action_events(action, remaps);
		elif key == SETTINGS_GROUP:
			for setting_key in value.keys():
				var setting_value = value[setting_key]
				if setting_key is not String \
					or setting_value is not String:
					continue

				if setting_value.contains("Object("):
					continue

				add_or_set_setting(setting_key, str_to_var(setting_value))
