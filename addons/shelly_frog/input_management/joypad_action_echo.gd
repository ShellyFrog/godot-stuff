@icon("./_icons/JoypadActionEcho.svg")
class_name JoypadActionEcho
extends Node
## Node that emits repeated events for joypads if an action is held.
## This is also known as an "echo" event and is usually a keyboard feature
## in an OS. See [member InputEvent.is_echo()].

## The time in seconds to wait until echo events are sent.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var wait_time: float = 0.5
## The delay in seconds between repeats of echo events.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var repeat_time: float = 0.1

## The actions to emit echo events for.
@export var _actions: Array[StringName] = [
	&"ui_left",
	&"ui_right",
	&"ui_up",
	&"ui_down",
]

var _waiting_for_actions: Array[StringName]
var _timers: Dictionary[StringName, Timer]
var _press_events: Dictionary[StringName, InputEventAction]
var _release_events: Dictionary[StringName, InputEventAction]


func _ready():
	# This should work while paused too.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent):
	if event is not InputEventJoypadButton and event is not InputEventJoypadMotion:
		return

	for action in _actions:
		if not event.is_action(action):
			continue

		if (
				event.is_pressed()
				and Input.is_action_just_pressed(action)
				and not _waiting_for_actions.has(action)
				and not _timers.has(action)
		):
			_waiting_for_actions.append(action)
			var wait_timer: SceneTreeTimer = get_tree().create_timer(wait_time)
			wait_timer.timeout.connect(_create_echo.bind(action, event))
		elif event.is_released() and Input.is_action_just_released(action):
			if _waiting_for_actions.has(action):
				_waiting_for_actions.erase(action)
				return

			if not _timers.has(action):
				return

			var timer = _timers[action]
			_timers.erase(action)

			remove_child(timer)
			timer.queue_free()

			# Make sure to release the input.
			Input.parse_input_event(_release_events[action])

			_press_events.erase(action)
			_release_events.erase(action)


func _create_echo(action: StringName, event: InputEvent):
	if not _waiting_for_actions.has(action):
		return

	_waiting_for_actions.erase(action)

	var press_event := InputEventAction.new()
	press_event.device = event.device
	press_event.action = action
	press_event.pressed = true
	_press_events[action] = press_event

	var release_event := InputEventAction.new()
	release_event.device = event.device
	release_event.action = action
	release_event.pressed = false
	_release_events[action] = release_event

	var repeat_timer := Timer.new()
	repeat_timer.name = action
	repeat_timer.wait_time = repeat_time
	repeat_timer.autostart = true
	add_child(repeat_timer)

	_timers[action] = repeat_timer

	repeat_timer.timeout.connect(func():
		Input.parse_input_event(_press_events[action])
		Input.parse_input_event(_release_events[action])
	)
