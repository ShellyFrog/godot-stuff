@icon("./_icons/InputPlayer.svg")
class_name InputPlayer
extends Node
## Node that handles multiplayer input and action remapping automatically
## by creating new actions and events using an optional [InputProfile].

## Emitted when the last device used by this player changed.
signal last_active_device_changed(device: int)
## Emitted when this player is processing unhandled input.
signal unhandled_input_received(event: InputEvent)

## Whether this player uses the keyboard or not.
## Godot currently only supports one keyboard, so it is recommended to only
## enable this on one player.
@export var use_keyboard: bool = false:
	set(value):
		use_keyboard = value
		_rebuild_actions()
## The maximum amount of devices this player can own.
## If [code]-1[/code], all devices will be used by this player.
## [br]
## [b]Note:[/b] If set to a lower value than is currently set
## - other than [code]-1[/code] - the devices used by this player will be unassigned
## in order of assignment.
@export_range(-1, 8, 1, "or_greater") var max_devices: int = -1:
	set(value):
		max_devices = max(value, -1)
		if value != -1 and _devices.size() > value:
			_devices.resize(value)
			_rebuild_actions()

var _id: int = -1
var _last_active_device: int = -1

## Whether to ignore the unhandled input callback for this player.
## This can be used to block input temporarily.
var ignore_unhandled_input: bool = false

var _system: InputPlayerSystem
var _devices: PackedInt32Array
var _input_profile: InputProfile
var _action_cache: Dictionary[StringName, StringName]


func _unhandled_input(event: InputEvent):
	if ignore_unhandled_input:
		return

	if caused_event(event):
		if _last_active_device != event.device:
			_last_active_device = event.device
			last_active_device_changed.emit(event.device)

		unhandled_input_received.emit(event)
		get_viewport().set_input_as_handled()


## Initializes all player actions.
func initialize(new_id: int, system: InputPlayerSystem):
	_id = new_id
	_last_active_device = -1
	_system = system

	for action: StringName in _system.player_actions:
		_action_cache[action] = _create_action_string_name(action)
	_rebuild_actions()


## Returns the ID used to identify this player in [InputPlayerSystem].
func get_id() -> int:
	return _id


## Returns whether this player uses the device that emitted [param event].
func caused_event(event: InputEvent) -> bool:
	return (
			(use_keyboard and (event is InputEventKey or event is InputEventMouse))
			or _devices.has(event.device)
	)


## Returns the regular [param action] name as the action name exclusive to this player.
func get_player_action_name(action: StringName) -> StringName:
	if not _action_cache.has(action):
		_action_cache[action] = _create_action_string_name(action)
	return _action_cache[action]


## Sets [member use_keyboard] and rebuilds all player actions.
func set_use_keyboard(p_use_keyboard: bool):
	if use_keyboard == p_use_keyboard:
		return
	use_keyboard = p_use_keyboard
	_rebuild_actions()


## Returns whether this player can accept a new device to use.
## See [member max_devices].
func can_accept_new_devices() -> bool:
	return max_devices == -1 or _devices.size() < max_devices


## Makes this player use [param device].
func add_device(device: int):
	if not can_accept_new_devices():
		return
	if _devices.has(device):
		return

	_devices.append(device)
	_rebuild_actions()


## Makes this player stop using [param device].
func remove_device(device: int) -> bool:
	if _devices.erase(device):
		_rebuild_actions()
		return true
	return false


## Returns the device id of the last active device this player received input from
## or [code]-1[/code] if there has not been any input for this player yet.
## [br]
## See [member InputEvent.device].
func get_last_active_device() -> int:
	return _last_active_device


## Sets the input remapping profile to use for this player.
func set_input_profile(profile: InputProfile):
	_input_profile = profile
	_rebuild_actions()


## Wrapper for [method Input.get_axis].
func get_axis(negative_action: StringName, positive_action: StringName) -> float:
	return Input.get_axis(get_player_action_name(negative_action), get_player_action_name(positive_action))


## Wrapper for [method Input.get_vector].
func get_vector(negative_x: StringName, positive_x: StringName, negative_y: StringName, positive_y: StringName) -> Vector2:
	return Input.get_vector(
			get_player_action_name(negative_x),
			get_player_action_name(positive_x),
			get_player_action_name(negative_y),
			get_player_action_name(positive_y),
	)


## Wrapper for [method Input.is_action_pressed].
func is_action_pressed(action: StringName, exact_match: bool = false) -> bool:
	return Input.is_action_pressed(get_player_action_name(action))


## Wrapper for [method Input.is_action_just_pressed].
func is_action_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(get_player_action_name(action))


## Wrapper for [method Input.is_action_just_released].
func is_action_just_released(action: StringName) -> bool:
	return Input.is_action_just_released(get_player_action_name(action))


func _rebuild_actions():
	if not _system:
		return

	FrogLog.debug("Rebuilding actions for player %d" % get_id())

	for action: StringName in _system.player_actions:
		var player_action: StringName = get_player_action_name(action)
		FrogLog.debug("Building Action \"%s\"..." % player_action)

		if InputMap.has_action(player_action):
			InputMap.action_erase_events(player_action)
		else:
			InputMap.add_action(player_action)

		var events: Array[InputEvent] = _get_action_events_with_remaps(action)
		for event: InputEvent in events:
			if event is InputEventKey or event is InputEventMouse:
				if use_keyboard:
					InputMap.action_add_event(player_action, event)
			else:
				_add_event_for_devices(player_action, event)


func _add_event_for_devices(action: StringName, event: InputEvent):
	if max_devices == -1:
		InputMap.action_add_event(action, event)
	else:
		for device in _devices:
			var device_event = event.duplicate()
			device_event.device = device
			InputMap.action_add_event(action, device_event)


func _get_action_events_with_remaps(action: StringName) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	if _input_profile:
		events = _input_profile.get_action_events(action)
	if events.is_empty():
		events = InputMap.action_get_events(action)
	return events


func _create_action_string_name(action: StringName):
	return "%s:%s" % [action, _id]
