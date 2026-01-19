@icon("./_icons/FiniteStateMachine.svg")
class_name FiniteStateMachine
extends FiniteState
## Node representing a finite state machine.
##
## This node handles [FiniteState] transitions and callbacks
## such as their frame processing, physics processing, and input processing.
## [br]
## By default the state machine automatically assigns itself all child states
## and uses their child index as their ID.
## You can manually assign IDs and states by setting [member _state_map]
## in the [method _initialize] function.
## [br]
## A state machine is also a [FiniteState] itself, allowing for nested
## state machines.

## Emitted when a new state has been transitioned to.[br]
## This is [b]not[/b] emitted when the state is changed manually
## or by using [method set_state].
signal state_changed(old_state: FiniteState, new_state: FiniteState)

enum StateMachineType {
	## This state machine will enter its start state automatically.
	ROOT,
	## This state machine must be handled by another state machine.
	SUB_STATE_MACHINE,
}

enum UpdateMode {
	## The state machine has to be updated manually.
	MANUAL,
	## The state machine updates automatically through engine callbacks.
	AUTOMATIC,
}

## How to treat this state machine.
@export var type := StateMachineType.ROOT
## The state to start from.
## If not set the first state in [member _state_map] will be used.
## By default this will be the first child of this node that
## is a [FiniteState].
@export var starting_state: FiniteState
@export_group("Update Modes", "mode")
## How this state machine should handle frame processing.
@export var mode_process := UpdateMode.AUTOMATIC:
	set(value):
		if mode_process == value:
			return
		mode_process = value
		set_process(value == UpdateMode.AUTOMATIC)
## How this state machine should handle physics processing.
@export var mode_physics := UpdateMode.AUTOMATIC:
	set(value):
		if mode_physics == value:
			return
		mode_physics = value
		set_physics_process(value == UpdateMode.AUTOMATIC)

## The currently active state.
var current_state: FiniteState:
	set(value):
		set_state(_state_map.find_key(value))
	get:
		return _state

var _state: FiniteState
var _state_map: Dictionary[int, FiniteState]


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		return

	_initialize()

	if _state_map.is_empty():
		var state: FiniteState
		for child: Node in get_children():
			state = child as FiniteState
			if state:
				_state_map[state.get_index()] = state

	for state: FiniteState in _state_map.values():
		if not starting_state:
			starting_state = state
		state.initialize(self)
		state.finished.connect(transition_to)

	if type == StateMachineType.ROOT:
		enter(null)
		FrogLog.debug("%s start state entered." % name)

	set_process(mode_process == UpdateMode.AUTOMATIC)
	set_physics_process(mode_physics == UpdateMode.AUTOMATIC)


func _process(delta: float) -> void:
	_state_process(delta)


func _physics_process(delta: float) -> void:
	_state_physics_process(delta)


func _can_transition_to() -> bool:
	return current_state._can_transition_to()


func _enter(previous_state: FiniteState):
	var old_state: FiniteState = current_state
	current_state = starting_state
	current_state.enter(null)
	state_changed.emit(old_state, current_state)


func _exit(next_state: FiniteState):
	current_state.exit(null)


func _state_process(delta: float):
	current_state._state_process(delta)


func _state_physics_process(delta: float):
	current_state._state_physics_process(delta)


func _handle_input(input: int, state: InputState) -> bool:
	return current_state._handle_input(input, state)


## Returns the ID used in [member _state_map] for the
## currently active state.
func get_current_state_id() -> int:
	return get_state_id(current_state)


## Returns the ID used in [member _state_map] for [param state].
## Returns [code]-1[/code] if the state is not handled by this
## state machine.
func get_state_id(state: FiniteState) -> int:
	var id = _state_map.find_key(state)
	if id == null:
		return -1
	return id as int


## Sets the state without any callbacks.
## Use [method transition_to] if you want the enter and exit
## callbacks to be called.
func set_state(state_id: int):
	var new_state: FiniteState = _state_map.get(state_id, null)
	if not new_state:
		return
	_state = new_state


## Transitions from the current state to the state with ID [param state_id]
## if it exists in [member _state_map]. Enter and exit callbacks of the state are called.
## [br]
## Returns [code]false[/code] if the transition failed.
## See [method FiniteState._can_transition_to].
func transition_to(state_id: int) -> bool:
	var next_state: FiniteState = _state_map.get(state_id, null)
	if not next_state or not next_state._can_transition_to():
		return false

	var previous_state: FiniteState = current_state

	previous_state.exit(next_state)

	current_state = next_state
	current_state.enter(previous_state)

	state_changed.emit(previous_state, current_state)
	return true


## Called when this state machine is ready.
## If you do not manually populate [member _state_map] in this function
## all children of the state machine with their index will be assigned.
## [br]
## Example:
## [codeblock]
## enum State {
##     STATE_IDLE,
##     STATE_MOVE,
##     STATE_ATTACK,
## }
## 
## _state_map = {
##     State.STATE_IDLE: idle_state,
##     State.STATE_MOVE: move_state,
##     State.STATE_ATTACK: attack_state,
## }
## [/codeblock]
func _initialize():
	pass
