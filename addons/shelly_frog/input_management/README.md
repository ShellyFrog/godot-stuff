
## Input Player System

Files:
- `input_player_system.gd`
- `input_player.gd`
- `input_profile.gd`

Optional:
- `input_profile_provider.gd`


System for handling the concept of "players" for input in Godot.

This means that individual players can be assigned different input devices and queried on what input corresponds to them.

The basic setup works as follows:  
1. Have an autoload scene with a `input_player_system.gd` node as the root.

2. Configure the `player_actions` property of the root node to include all actions you want to be usable by each player.  
Unfortunately this has to be done manually as there is no surefire way to retrieve only non built-in actions from the project settings as of Godot 4.5

3. Add `input_player.gd` child nodes as needed. This can also be done with the node creation dialog under the name "InputPlayer". These will automatically be assigned an ID starting with 0.

4. Now you can access the player system as such:  
```gdscript
var player: InputPlayer = InputSystemAutoload.get_player(0)
if player.is_action_just_pressed(&"jump"):
    # Jump.
```

Preferably the InputPlayer node should be cached.

Input remapping works as follows:  
```gdscript
var profile: InputProfile = InputProfile.new()
profile.add_event_to_action(&"jump", <some new event>)
# Or profile.set_action_events(&"jump", <event array>)

# Set the player to use this profile.
InputSystemAutoload.get_player(0).set_input_profile(profile)
# Set the player back to default actions.
InputSystemAutoload.get_player(0).set_input_profile(null)
```

`input_profile_provider.gd` is a database for loading, storing, deleting and providing input profiles across the game.  
You can also implement your own system for doing this if you'd like.

See the in-engine documentation for more info on these nodes.

## Joypad Echo

In Godot keyboard keys fire "echo" events, meaning they send repeated inputs when held. This is particularly useful in UI and joypads do not have this functionality by default.  
`joypad_action_echo.gd` implements this.

To use it add a `JoypadActionEcho` node anywhere in the game, preferably with an autoload if you want it to be functional at all times.

By default it will echo the events `ui_left`, `ui_right`, `ui_up`, and `ui_down`.  
You can modify this by changing the `actions` property of the node.

To make this compatible with the player system above add the respective ID of the player at the end of action names like: `ui_left:0`, `ui_right:0`, etc.
