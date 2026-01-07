@tool
@icon("./_icons/MotionTrail3D.svg")
class_name MotionTrail3D
extends MeshInstance3D
## A node that creates a trail mesh based on past positions.

enum TextureMapping {
	## The texture will stretch across the length
	## of the entire trail.
	STRETCH,
	## The texture will tile across the trail.
	TILE,
}

enum Space {
	## The trail will emit points when it is moved locally.
	LOCAL,
	## The trail will emit points when it moves in world space.
	## This means the parent moving will also emit points.
	GLOBAL,
}

enum Alignment {
	## The trail mesh will be aligned to its local transform.
	LOCAL,
	## The trail mesh will be aligned to face the camera.
	VIEW,
}

## If [code]true[/code] the trail will emit points.
## [br]
## [b]Note:[/b] The mesh will continue to update regardless
## of the value of this property as long as this node has not
## been paused.
@export var emitting: bool = true:
	set(value):
		emitting = value
		if not emitting and not _points.is_empty():
			_points[-1].is_discontinuity = true

@export_group("Rendering")
## The material used to render the trail mesh.
@export var material := StandardMaterial3D.new()
## Determines how the trail mesh should be aligned.
@export var alignment_mode := Alignment.VIEW
## The space to use for evaluating whether to emit a trail point.
@export var simulation_space := Space.GLOBAL:
	set(value):
		if simulation_space == value:
			return
		_update_simulation_space(value)
		simulation_space = value
## Overrides the transform used with [member simulation_space].
## [br]
## This can be used for cases such as needing the trail to be in
## local space but wanting parent rotation to cause points to emit.
@export var simulation_parent: Node3D

@export_subgroup("Spawn")
## The distance in meters the trail has to move for a new
## point to be emitted.
@export_range(0.001, 1.0, 0.01, "suffix:m")
var min_distance_between_points: float = 0.025
## The minimum time in seconds that has to pass before a new point
## can be emitted.
@export_range(0.0, 1.0, 0.01, "suffix:s")
var min_time_between_points: float = 0.025
## The amount of time in seconds before a newly emitted point
## will be removed from the trail.
@export_range(0.001, 5.0, 0.01, "or_greater")
var life_time: float = 1.0

@export_subgroup("Color")
## The base color of the trail.
@export var start_color := Color.WHITE
## A color multiplier depending on how long the trail is.
@export var color_over_length: Gradient
## A color multiplier depending on how long a point has existed.
@export var color_over_life_time: Gradient

@export_subgroup("Width")
## The base width of the trail.
@export_range(0.01, 1.0, 0.01, "or_greater")
var start_width: float = 0.1
## A multiplier to the trail width over its length.
@export var width_over_length := Curve.new()
## A multiplier to the trail width depending on how
## long a point has existed.
@export var width_over_lifetime := Curve.new()

@export_subgroup("UVs")
## Determines how the trail UVs should be generated.
@export var texture_mapping: TextureMapping
## Determines the U size of the texture UVs.
@export var texture_mapping_width: float = 1.0
## Determines at what point the U axis is anchored
## for the trail UVs.
@export_range(0.0, 1.0)
var texture_mapping_anchor: float = 1.0

@export_subgroup("Smoothing")
## If set higher than [code]1[/code] a Catmull-Rom interpolation
## will be applied to the trail points, giving it a smoother appearance
## at the cost of performance.
@export_range(1, 8)
var interpolation_iterations: int = 3

@export_group("Physics")
## If [code]true[/code], the trail points will have
## physics simulated for them.
## [br]
## [b]Note:[/b] This does not interact with the regular
## physics system.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only")
var enable_physics: bool = false:
	set(value):
		if enable_physics == value:
			return
		enable_physics = value
		set_physics_process(value)
## If [code]true[/code], points will automatically be emitted
## while physics are enabled.
@export var auto_emit_physics_points: bool = true
## The base velocity of any point in the space of [member simulation_space].
@export var start_velocity := Vector3.ZERO
## The gravity applied to each point in world space.
@export var gravity := Vector3.ZERO
## The ratio of velocity the trail points should keep
## while moving. This is similar to
## [member ParticleProcessMaterial.inherit_velocity_ratio].
@export_range(0.0, 1.0)
var inherit_velocity_ratio: float = 0.0
## How quickly the point velocity should adjust to the node's
## actual velocity.
@export_range(0.0, 1.0)
var velocity_change_rate: float = 0.75
## How quickly the point velocity should decrease.
@export_range(0.0, 1.0)
var velocity_damping: float = 0.75

var _velocity: Vector3
var _last_valid_position: Vector3
var _time_since_last_point: float

var _mesh: ImmediateMesh
var _points: Array[Point] = []
var _active_segment_points: Array[Point] = []

var _paused: bool


func _enter_tree():
	_last_valid_position = _get_current_position()

	if Engine.is_editor_hint() and _mesh:
		mesh = _mesh
		return

	_mesh = ImmediateMesh.new()
	mesh = _mesh

	RenderingServer.frame_pre_draw.connect(_update_trail)


func _exit_tree():
	RenderingServer.frame_pre_draw.disconnect(_update_trail)
	clear()


func _process(delta: float):
	var position: Vector3 = _get_current_position()

	# Movement velocity
	if delta > 0.0:
		_velocity = _velocity.move_toward((position - _last_valid_position) / delta, velocity_change_rate * delta)

	_create_new_point_if_needed(position, delta)

	if _points.is_empty():
		return

	var last_point: Point = _points[-1]
	if not emitting:
		last_point.is_discontinuity = true
	if not last_point.is_discontinuity:
		# Snap last point to the current position.
		last_point.position = position
		last_point.normal = basis.y
		last_point.tangent = -basis.z

	# Update point lifetimes and handle removal.
	var to_remove: PackedInt32Array
	var point_count: int = _points.size()
	for i: int in point_count:
		_points[i].life_time -= delta
		if _points[i].life_time <= 0.0:
			# Only non-interpolated points die instantly.
			if interpolation_iterations == 1 || i > point_count - 3:
				to_remove.append(i)
			else:
				if (
						_points[i + 1].life_time <= 0.0
						and _points[i + 2].life_time <= 0.0
				):
						to_remove.append(i)

	for i: int in to_remove:
		_points.remove_at(i)


func _simulate_physics(delta: float):
	var damping: float = pow(1.0 - velocity_damping, delta)
	for i: int in _points.size():
		var point: Point = _points[i]
		point.velocity += gravity * delta
		point.velocity *= damping
		point.position += point.velocity * delta
		_points[i] = point


func _notification(notification: int):
	match notification:
		NOTIFICATION_PHYSICS_PROCESS:
			_simulate_physics(get_physics_process_delta_time())
		NOTIFICATION_PAUSED:
			_paused = true
		NOTIFICATION_UNPAUSED:
			_paused = false


## Clears all emitted points and the mesh.
func clear():
	_points.clear()
	_mesh.clear_surfaces()


func _update_trail():
	if _paused:
		return
	_create_mesh()


func _update_simulation_space(new: Space):
	match new:
		Space.LOCAL:
			for point: Point in _points:
				point.position = point.position * _get_parent_transform()
				point.velocity = (_get_transform().basis * point.velocity) * _get_parent_transform().basis
		Space.GLOBAL:
			for point: Point in _points:
				point.position = _get_parent_transform() * point.position
				point.velocity = _get_parent_transform() * point.velocity


func _get_transform() -> Transform3D:
	return (
			get_global_transform_interpolated()
			if is_physics_interpolated_and_enabled()
			else global_transform
	)


func _get_parent_transform() -> Transform3D:
	var parent: Node3D = simulation_parent
	if not parent:
		parent = get_parent_node_3d()
	if not parent:
		return Transform3D.IDENTITY
	return (
			parent.get_global_transform_interpolated() 
			if parent.is_physics_interpolated_and_enabled() 
			else parent.global_transform
	)


func _get_current_position() -> Vector3:
	var transform: Transform3D = _get_transform()
	if simulation_space == Space.GLOBAL:
		return transform.origin
	else:
		return transform.origin * _get_parent_transform()


func _create_new_point_if_needed(position: Vector3, delta: float):
	if min_time_between_points > 0.0:
		_time_since_last_point += delta

	if _time_since_last_point < min_time_between_points:
		return

	if enable_physics and auto_emit_physics_points:
		if _points.size() > 0 and position.distance_squared_to(_points[-1].position) < min_distance_between_points * min_distance_between_points:
			return
	elif position.distance_squared_to(_last_valid_position) < min_distance_between_points * min_distance_between_points:
		return

	var velocity: Vector3 = start_velocity
	if simulation_space != Space.GLOBAL:
		velocity = (_get_transform().basis * velocity) * _get_parent_transform().basis

	# Store the local basis by default when creating the mesh.
	_points.append(Point.new(position, -basis.z, basis.y, velocity + (_velocity * inherit_velocity_ratio), life_time))

	_last_valid_position = position
	_time_since_last_point = 0.0


func _create_mesh():
	if _points.size() < 2:
		return

	_mesh.clear_surfaces()

	var segment_start: int = 0
	for i: int in _points.size():
		if _points[i].is_discontinuity or i == _points.size() - 1:
			_create_segment_mesh(segment_start, i)
			segment_start = i + 1


func _create_segment_mesh(start: int, end: int):
	_create_segment_points(start, end)

	if _active_segment_points.size() < 2:
		return

	var segment_length: float = 0.0
	for i: int in _active_segment_points.size() - 1:
		segment_length += _active_segment_points[i].position.distance_to(_active_segment_points[i + 1].position)

	if is_zero_approx(segment_length):
		return

	var length: float = 0.0
	var texture_offset: float = 0.0 if texture_mapping == TextureMapping.STRETCH else (-texture_mapping_width * segment_length * texture_mapping_anchor)
	var uv := Vector2.ZERO
	var width: float = start_width
	var color: Color = start_color
	var transform: Transform3D = _get_transform()
	var inverse_transform: Transform3D = transform.inverse()
	var parent_transform: Transform3D
	var inverse_parent_transform: Transform3D
	if is_instance_valid(simulation_parent):
		parent_transform = _get_parent_transform()
		inverse_parent_transform = parent_transform.inverse()

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)

	for i: int in range(_active_segment_points.size() - 1, -1, -1):
		var point: Vector3 = _active_segment_points[i].position

		var tangent: Vector3 = -(_active_segment_points[i + 1].position - point) if i == 0 else _active_segment_points[i - 1].position - point
		var distance_to_next_point: float = tangent.length()
		tangent /= distance_to_next_point

		var normal: Vector3
		var bitangent: Vector3

		if alignment_mode == Alignment.LOCAL:
			# The local basis is stored by default with each point.
			tangent = _active_segment_points[i].tangent
			normal = _active_segment_points[i].normal
		else:
			var camera: Camera3D
			if Engine.is_editor_hint():
				var editor_interface = Engine.get_singleton(&"EditorInterface")
				if editor_interface:
					camera = editor_interface.get_editor_viewport_3d().get_camera_3d()
			else:
				camera = get_viewport().get_camera_3d()

			var camera_position := Vector3.ZERO

			if camera:
				# Tangent is already calculated for the sake of getting the distance to the next point.
				# The camera is not interpolated, it moves in _process() so no need for
				# get_global_transform_interpolated.
				if simulation_space == Space.GLOBAL:
					camera_position = camera.global_position
				else:
					if is_instance_valid(simulation_parent):
						# to_local
						camera_position = inverse_parent_transform * camera.global_position
					else:
						# to_local
						camera_position = inverse_transform * camera.global_position

			normal = -point.direction_to(camera_position)

		bitangent = tangent.cross(normal).normalized()

		var length_t: float = length / segment_length
		var life_t: float = clampf(1.0 - (_active_segment_points[i].life_time / life_time), 0.0, 1.0)
		length += distance_to_next_point

		texture_offset += texture_mapping_width * (distance_to_next_point / segment_length) if texture_mapping == TextureMapping.STRETCH else distance_to_next_point

		width = start_width * width_over_lifetime.sample_baked(life_t) * width_over_length.sample_baked(length_t)
		color = start_color * color_over_life_time.sample(life_t) * color_over_length.sample(length_t)

		# Avoid absolute zero width.
		width = max(width, 0.001)

		# The mesh has to be drawn relative to the transform.
		if simulation_space == Space.GLOBAL:
			# to_local
			point = inverse_transform * point
			normal = inverse_transform.basis * normal
			bitangent = inverse_transform.basis * bitangent
		else:
			if is_instance_valid(simulation_parent):
				# Similar to global space, the values need to be converted to this node's local space
				# This is doe with Local space in override -> Global space -> Local space for this node.
				point = inverse_transform * (parent_transform * point)
				normal = inverse_transform.basis * (parent_transform.basis * normal)
				bitangent = inverse_transform.basis * (parent_transform.basis * bitangent)
			else:
				# The positions are already local,
				# so they only need to be offset by the current position.
				point -= position

		normal = normal.normalized()
		bitangent = bitangent.normalized()

		# The normal, tangent and color are all shared between the left and right points.
		_mesh.surface_set_normal(normal)
		_mesh.surface_set_tangent(Plane(-bitangent))
		_mesh.surface_set_color(color)

		# Left.
		uv.x = texture_offset
		uv.y = 0.0
		_mesh.surface_set_uv(uv)
		_mesh.surface_add_vertex(point - bitangent * width * 0.5)

		# Right.
		uv.y = 1.0
		_mesh.surface_set_uv(uv)
		_mesh.surface_add_vertex(point + bitangent * width * 0.5)

	_mesh.surface_end()


func _create_segment_points(start: int, end: int):
	_active_segment_points.clear()

	if interpolation_iterations == 1:
		_active_segment_points = _points.slice(start, end - start + 1)
		return

	# Catmull-rom spline interpolation between each set of 4 points.
	var step_size: float = 1.0 / interpolation_iterations
	for i: int in range(start, end):
		# Extrapolate first and last points.
		var start_point: Point
		if i == start:
			start_point = Point.add(_points[start], Point.subtract(_points[start], _points[i + 1]))
		else:
			start_point = _points[i - 1]

		var end_point: Point
		if i == end - 1:
			end_point = Point.add(_points[end], Point.subtract(_points[end], _points[end - 1]))
		else:
			end_point = _points[i + 2]

		for j: int in range(interpolation_iterations):
			var t: float = j * step_size
			var interpolated_point := Point.interpolate(
					start_point,
					_points[i],
					_points[i + 1],
					end_point,
					t,
			)

			if interpolated_point.life_time > 0.0:
				_active_segment_points.append(interpolated_point)

	if _points[end].life_time > 0.0:
		_active_segment_points.append(_points[end])


class Point:
	var position: Vector3
	var tangent: Vector3
	var normal: Vector3
	var velocity: Vector3
	var life_time: float

	var is_discontinuity: bool = false


	func _init(p_position: Vector3, p_tangent: Vector3, p_normal: Vector3, p_velocity: Vector3, p_life_time: float):
		position = p_position
		tangent = p_tangent
		normal = p_normal
		velocity = p_velocity
		life_time = p_life_time


	static func add(p1: Point, p2: Point) -> Point:
		return Point.new(
				p1.position + p2.position,
				p1.tangent + p2.tangent,
				p1.normal + p2.normal,
				p1.velocity + p2.velocity,
				p1.life_time + p2.life_time,
		)


	static func subtract(p1: Point, p2: Point) -> Point:
		return Point.new(
				p1.position - p2.position,
				p1.tangent - p2.tangent,
				p1.normal - p2.normal,
				p1.velocity - p2.velocity,
				p1.life_time - p2.life_time,
		)


	static func interpolate(a: Point, b: Point, c: Point, d: Point, t: float) -> Point:
		return Point.new(
			_catmull_rom_3d(a.position, b.position, c.position, d.position, t),
			_catmull_rom_3d(a.tangent, b.tangent, c.tangent, d.tangent, t),
			_catmull_rom_3d(a.normal, b.normal, c.normal, d.normal, t),
			_catmull_rom_3d(a.velocity, b.velocity, c.velocity, d.velocity, t),
			_catmull_rom(a.life_time, b.life_time, c.life_time, d.life_time, t),
		)


	static func _catmull_rom(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
		return (
				0.5 * ((2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t +
				(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)
		)


	static func _catmull_rom_3d(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
		return Vector3(
			_catmull_rom(p0.x, p1.x, p2.x, p3.x, t), 
			_catmull_rom(p0.y, p1.y, p2.y, p3.y, t), 
			_catmull_rom(p0.z, p1.z, p2.z, p3.z, t),
		)
