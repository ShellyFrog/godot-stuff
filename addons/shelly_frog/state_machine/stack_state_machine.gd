@icon("./_icons/StackStateMachine.svg")
class_name StackStateMachine
extends FiniteStateMachine
## A [FiniteStateMachine] that implements a push automaton.
##
## The push automata allows for returning to previous states
## automatically by calling [method push_state] and then using
## [method transition_to] with the state ID [constant STATE_PREVIOUS].

## The ID for the previous state.
const STATE_PREVIOUS: int = -1

var _state_stack: Array[FiniteState]


func _ready() -> void:
	super()
	clear_stack()


## Transitions from the current state to the state with ID [param state_id]
## if it exists in [member _state_map].
## [br]
## Returns [code]false[/code] if the transition failed.
## See [method FiniteState._can_transition_to].
## [br]
## [b]Note:[/b] The enter callback of the state is only called when not
## using [constant STATE_PREVIOUS].
func transition_to(state_id: int) -> bool:
	if state_id == STATE_PREVIOUS:
		if _state_stack.size() == 1:
			return false
		_state_stack.pop_front()
	else:
		var next_state: FiniteState = _state_map.get(state_id, null)
		if not next_state or not next_state._can_transition_to():
			return false
		_state_stack[0] = next_state

	var next_state: FiniteState = _state_stack[0]
	var previous_state: FiniteState = current_state

	previous_state.exit(next_state)

	current_state = next_state
	if state_id != STATE_PREVIOUS:
		current_state.enter(previous_state)

	state_changed.emit(previous_state, current_state)
	return true


## Pushes a state onto the stack.
func push_state(state: FiniteState):
	_state_stack.push_front(state)


## Clears the state stack, making returning to previous states impossible.
func clear_stack():
	_state_stack = [starting_state]
