@icon("./_icons/FiniteState.svg")
class_name FiniteState
extends Node
## Base node that represents a single state in a [FiniteStateMachine].

## Emitted after [method _enter] is called.
signal entered
## Emitted after [method _exit] is called.
signal exited

## Emit this when this state is done and needs to transition
## to a different state.
signal finished(next_state: int, push: bool)

enum InputState {
	PRESSED,
	RELEASED,
}

var _state_machine: FiniteStateMachine


## Initializes the state with the state machine it belongs to.
func initialize(state_machine: FiniteStateMachine):
	_state_machine = state_machine


## Enters the state and emits [signal entered].
func enter(previous_state: FiniteState):
	_enter(previous_state)
	entered.emit()


## Exits the state and emits [signal entered].
func exit(next_state: FiniteState):
	_exit(next_state)
	exited.emit()


## Returns whether this state can be transitioned to.
func _can_transition_to() -> bool:
	return true


## Called when this state was entered by a state machine.
func _enter(previous_state: FiniteState):
	pass


## Called when this state was exited by a state machine.
func _exit(next_state: FiniteState):
	pass


## Called when a state machine is in [method Node._process] step.
func _state_process(delta: float):
	pass


## Called when a state machine is in the [method Node._physics_process] step.
func _state_physics_process(delta: float):
	pass


## Called when an input has been made.
## Should return whether the input was handled or not.
func _handle_input(input: int, state: InputState) -> bool:
	return false
