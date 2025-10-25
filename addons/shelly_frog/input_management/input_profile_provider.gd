class_name InputProfileProvider
extends Node
## Database for providing, loading, and saving [InputProfile]s.

## Emitted when the available profiles have changed.
signal profiles_changed()

const NAME_KEY: String = "name"
const SETTINGS_KEY: String = "settings"
const BINDS_SECTION: String = "binds"

@export var _directory := "user://input_profiles/"
@export var _file_format := "input_profile%s.cfg"

var _profiles: Dictionary[StringName, InputProfile]
var _file_paths: Dictionary[InputProfile, String]


func _enter_tree():
	if not DirAccess.dir_exists_absolute(_directory):
		var error: Error = DirAccess.make_dir_recursive_absolute(_directory)
		if error != OK:
			FrogLog.error("Could not create input profile directory: %s", error_string(error))
			return

	var directory = DirAccess.open(_directory)

	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() != _file_format.get_extension().to_lower():
			continue

		var file_path: String = _directory + file_name
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			var error: Error = FileAccess.get_open_error()
			FrogLog.error("Failed to open input profile at %s: %s" % [file_path, error_string(error)])
			continue

		var text: String = file.get_as_text()
		text = SerializationUtil.strip_scripts(text)

		var config := ConfigFile.new()
		var parse_error: Error = config.parse(text)
		if parse_error != OK:
			FrogLog.error("Failed to parse input profile at %s: %s" % [file_path, error_string(parse_error)])
			continue

		var name: StringName = config.get_value(String(), NAME_KEY, String())
		var settings: Dictionary[StringName, Variant] = config.get_value(String(), SETTINGS_KEY, String())
		var binds: Dictionary[StringName, Array]

		for action: String in config.get_section_keys(BINDS_SECTION):
			var event_array: Array[InputEvent]
	
			var dict_array: Array = config.get_value(BINDS_SECTION, action, [])
			if dict_array.is_empty():
				continue
	
			for item in dict_array:
				if item is not Dictionary:
					continue
				var dict := item as Dictionary
				var event: InputEvent = InputProfile.parse_event_dict(dict)
				if event:
					event_array.append(event)
	
			if event_array.is_empty():
				continue
	
			binds[action] = event_array

		var profile := InputProfile.create(name, binds, settings)
		if profile == null:
			continue

		if not _profiles.has(profile.name):
			_profiles[profile.name] = profile
			_file_paths[profile] = file_path
			profile.name_changed.connect(_on_profile_name_changed)


## Returns the amount of [InputProfile]s available.
func get_profile_count() -> int:
	return _profiles.size()


## Returns whether an [InputProfile] matching [param name]
## is available.
func has_profile(name: StringName):
	return _profiles.has(name)


## Returns an [InputProfile] matching [param name] if it exists,
## otherwise [code]null[/code].
func get_profile(name: StringName) -> InputProfile:
	return _profiles.get(name, null)


## Adds a new [InputProfile] and saves it to disk.
func add_profile(profile: InputProfile):
	profile.name_changed.connect(_on_profile_name_changed)
	save_profile(profile)
	profiles_changed.emit()


## Saves [param profile] to disk.
## [br]
## Returns [constant OK] if successful.
func save_profile(profile: InputProfile) -> Error:
	if not DirAccess.dir_exists_absolute(_directory):
		var error = DirAccess.make_dir_recursive_absolute(_directory)
		if error != OK:
			return error

	var file_path: String
	if _file_paths.has(profile):
		file_path = _file_paths[profile]
	else:
		var profile_number: int = _profiles.size();
		var file_name = _file_format % profile_number
		file_path = _directory + file_name

		while _file_paths.values().has(file_path):
			profile_number += 1

			file_name = _file_format % profile_number
			file_path = _directory + file_name

		_file_paths[profile] = file_path

	var config := ConfigFile.new()
	config.set_value(String(), NAME_KEY, profile.name)
	config.set_value(String(), SETTINGS_KEY, profile.settings)
	for action: StringName in profile.binds:
		config.set_value(BINDS_SECTION, action, profile.binds[action].map(
				func(event: InputEvent):
					return InputProfile.get_event_dict(event)
		))

	var error: Error = config.save(file_path)
	if error != OK:
		FrogLog.error("Failed to save input profile to %s: %s" % [file_path, error_string(error)])
		return error

	if not _profiles.has(profile.name):
		_profiles[profile.name] = profile
		profiles_changed.emit()

	return OK


## Removes a profile matching [param name] and deletes it
## from disk if it exists.
## [br]
## Returns [constant OK] if successful.
func delete_profile(name: StringName) -> Error:
	if not _profiles.has(name):
		return ERR_DOES_NOT_EXIST
	
	var profile: InputProfile = _profiles[name]

	_profiles.erase(name)
	profiles_changed.emit()

	if _file_paths.has(profile):
		var error: Error = DirAccess.remove_absolute(_file_paths[profile])
		if error != OK:
			return error
		_file_paths.erase(profile)

	return OK


## Returns the name of the first available [InputProfile].
## If none are available, returns an empty [StringName]
func get_first_available_profile_name() -> StringName:
	if _profiles.is_empty():
		return StringName()
	return _profiles.values()[0].name


func _on_profile_name_changed(old_name: StringName, new_name: StringName):
	var profile: InputProfile = _profiles[old_name];
	_profiles.erase(old_name)
	_profiles[new_name] = profile
	profiles_changed.emit()
