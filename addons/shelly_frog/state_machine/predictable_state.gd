@abstract
class_name PredictableState
extends FiniteState
## A [FiniteState] that handles logic and visuals separately.
## 
## Due to handling logic and visuals separately this class is useful
## for deterministic handling and rewinding of states.

## Emitted when the state was entered visually.
signal entered_visual
## Emitted when the state was exited visually.
signal exited_visual


## Should return whether visual updates are currently allowed or not.
## For example during a rollback situation this would return false.
@abstract
func is_allowed_visual_updates() -> bool


func _enter(previous_state: FiniteState):
	_enter_logic(previous_state)
	if is_allowed_visual_updates():
		_enter_visual(previous_state)
		entered_visual.emit()


func _exit(next_state: FiniteState):
	_exit_logic(next_state)
	if is_allowed_visual_updates():
		_exit_visual(next_state)
		exited_visual.emit()


## Called when the state should execute logical enter functionality.
func _enter_logic(previous_state: FiniteState):
	pass


## Called when the state should execute visual, audio, etc. enter functionality.
func _enter_visual(previous_state: FiniteState):
	pass


## Called when the state should execute logical exit functionality.
func _exit_logic(next_state: FiniteState):
	pass


## Called when the state should execute visual, audio, etc. exit functionality.
func _exit_visual(next_state: FiniteState):
		pass
