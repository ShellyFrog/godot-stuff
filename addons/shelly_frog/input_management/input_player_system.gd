class_name InputPlayerSystem
extends Node
## System for handling the concept of different players
## for input handling.

## The names of the actions that should be handled by each player.
@export var player_actions: Array[StringName]

var _players: Dictionary[int, InputPlayer]


func _enter_tree() -> void:
	var player_id: int = 0
	var player: InputPlayer
	for child in get_children():
		player = child as InputPlayer
		if player:
			player.initialize(player_id, self)
			_players[player_id] = player
			player_id += 1

	Input.joy_connection_changed.connect(_handle_joy_connection_changed)
	var joypads: PackedInt32Array = Input.get_connected_joypads()

	var message = "Connected Joypads (%s):\n" % joypads.size()
	for joypad in joypads:
		message += "[ul]\"%s\" (id: %s)[/ul]" % [Input.get_joy_name(joypad), joypad]
	FrogLog.message(message)


## Returns the amount of active [InputPlayer]s.
func get_player_count() -> int:
	return _players.size()


## Returns a player corresponding to [param id] if it exists,
## otherwise [code]null[/code].
func get_player(id: int) -> InputPlayer:
	return _players.get(id, null)


## Returns the player that caused [param event]
## if it exists, otherwise [code]null[/code].
func get_player_from_event(event: InputEvent) -> InputPlayer:
	for potential_player in _players.values():
		if potential_player.caused_event(event):
			return potential_player
	return null


func _handle_joy_connection_changed(device: int, connected: bool):
	if connected:
		FrogLog.message("Device %s (ID: %s) connected." % [Input.get_joy_name(device), device])
	else:
		FrogLog.message("Device with ID %s disconnected." % device)

	for player: InputPlayer in _players.values():
		if connected:
			if player.can_accept_new_devices():
				FrogLog.message("Device %s (ID: %s) was assigned to player %s" % [Input.get_joy_name(device), device, player.get_id() + 1])
				player.add_device(device)
				break
		else:
			if player.remove_device(device):
				FrogLog.message("Device with ID %s was unassigned from player %s" % [device, player.get_id() + 1])
