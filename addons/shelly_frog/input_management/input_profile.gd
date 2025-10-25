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

const TYPE: StringName = &"type"
const KEYCODE: StringName = &"keycode"
const KEYCODE_PHYSICAL: StringName = &"physical_keycode"
const KEY_LABEL: StringName = &"key_label"
const BUTTON_INDEX: StringName = &"button_index"
const AXIS: StringName = &"axis"
const AXIS_VALUE: StringName = &"axis_value"

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
var binds: Dictionary[StringName, Array]


## Returns a new input profile with the corresponding values.
static func create(name: StringName, binds: Dictionary[StringName, Array], settings_dict: Dictionary[StringName, Variant]) -> InputProfile:
	var profile := InputProfile.new()

	for action: StringName in binds:
		if not InputMap.has_action(action):
			continue
		var value = binds[action]
		if value is not Array:
			continue
		var array := (value as Array).filter(func(item): return item is InputEvent)
		profile.set_action_events(action, value as Array)

	profile.name = name
	profile.settings = settings_dict
	return profile


## Returns a dictionary that stores only the values of [param event]
## necessary to reconstruct for the purposes of input binding.
static func get_event_dict(event: InputEvent) -> Dictionary[StringName, Variant]:
	var event_data: Dictionary[StringName, Variant]
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
	return event_data


## Returns an input event created according to [param dictionary]
## which should match the format created by [method get_event_dict].
## Returns [code]null[/code] if there was an error.
static func parse_event_dict(dictionary: Dictionary) -> InputEvent:
	if not dictionary.has(TYPE):
		return null

	var event_type: EventType = dictionary.get(TYPE, -1)
	if event_type == -1:
		return null
	var event: InputEvent = null

	match event_type:
		EventType.KEY:
			if (
					not dictionary.has(KEYCODE)
					and not dictionary.has(KEYCODE_PHYSICAL)
					and not dictionary.has(KEY_LABEL)
			):
				return null

			event = InputEventKey.new()
			event.keycode = dictionary[KEYCODE]
			event.physical_keycode = dictionary[KEYCODE_PHYSICAL]
			event.key_label = dictionary[KEY_LABEL]

		EventType.MOUSE:
			if not dictionary.has(BUTTON_INDEX):
				return null

			event = InputEventMouseButton.new()
			event.button_index = dictionary[BUTTON_INDEX]

		EventType.JOY_BUTTON:
			if not dictionary.has(BUTTON_INDEX):
				return null

			event = InputEventJoypadButton.new()
			event.button_index = dictionary[BUTTON_INDEX]

		EventType.JOY_MOTION:
			if (
					not dictionary.has(AXIS)
					and not dictionary.has(AXIS_VALUE)
			):
				return null

			event = InputEventJoypadMotion.new()
			event.axis = dictionary[AXIS]
			event.axis_value = dictionary[AXIS_VALUE]

	return event


## Returns the input events for [param action].
## [br]
## [b]Note:[/b] This may return an empty array.
func get_action_events(action: StringName) -> Array[InputEvent]:
	# Doing this strange pattern because Dictionary.get(action, [])
	# results in an array type error.
	if binds.has(action):
		return binds[action]
	return []


## Sets all input events for [param action].
## [br]
## [b]Note:[/b] This overwrites any existing events.
func set_action_events(action: StringName, events: Array[InputEvent]):
	binds[action] = events
	emit_changed()


## Adds a single event for [param action] or creates a new
## array of input events for [param action] if it did not exist.
func add_event_to_action(action: StringName, input_event: InputEvent):
	if not input_event:
		return

	if binds.has(action):
		var events = binds[action]
		if not events.has(input_event):
			events.append(input_event)
	else:
		binds[action] = [input_event]

	emit_changed()


## Removes a single event from [param action] if it exists.
func remove_event_from_action(action: StringName, input_event: InputEvent):
	var events: Array = binds.get(action, null)
	if events:
		events.erase(input_event)
		if events.is_empty():
			binds.erase(action)

	emit_changed()


## Returns the value for a setting with the key [param key]
## if it exists, otherwise [code]null[/code].
func get_setting(key: StringName) -> Variant:
	return settings.get(key, null)


## Adds or overwrites the value for a setting with key [param key].
func add_or_set_setting(key: StringName, value):
	settings[key] = value
