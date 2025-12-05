extends EditorScenePostImportPlugin

const OPTION_PREFIX: String = "auto_hlod/"

const OPTION_ENABLED: String = OPTION_PREFIX + "enabled"
const OPTION_ENABLED_DEFAULT: bool = true
const OPTION_MAX_DISTANCE: String = OPTION_PREFIX + "max_distance"
const OPTION_MAX_DISTANCE_DEFAULT: float = 200.0
const OPTION_DISTRIBUTION: String = OPTION_PREFIX + "distribution"
const OPTION_DISTRIBUTION_DEFAULT: float = 5.0


func _get_import_options(path: String) -> void:
	add_import_option_advanced(TYPE_BOOL, OPTION_ENABLED, OPTION_ENABLED_DEFAULT)
	add_import_option_advanced(TYPE_FLOAT, OPTION_MAX_DISTANCE, OPTION_MAX_DISTANCE_DEFAULT, PROPERTY_HINT_RANGE, "0.1,500.0,0.1,suffix:m")
	add_import_option_advanced(TYPE_FLOAT, OPTION_DISTRIBUTION, OPTION_DISTRIBUTION_DEFAULT, PROPERTY_HINT_EXP_EASING, "attenuation")


func _get_option_visibility(path: String, for_animation: bool, option: String) -> Variant:
	var enabled: bool = get_option_value(OPTION_ENABLED)
	match option:
		OPTION_MAX_DISTANCE, OPTION_DISTRIBUTION:
			return enabled
		_:
			return null


func _post_process(scene: Node):
	var enabled: bool = get_option_value(OPTION_ENABLED)
	if not enabled:
		return

	var max_distance: float = get_option_value(OPTION_MAX_DISTANCE)
	var easing: float = get_option_value(OPTION_DISTRIBUTION)

	# Dictionary for containing all related LOD meshes.
	var dict := Dictionary()
	var instances: Array = scene.find_children("*", "GeometryInstance3D")
	for current: GeometryInstance3D in instances:
		if not is_instance_valid(current):
			continue

		var lod_index: int = current.name.rfindn("lod")
		if lod_index == -1 or current.name.length() <= lod_index:
			if current.name in dict:
				dict[current.name][current] = 0
			else:
				dict[current.name] = { current: 0 }
			continue

		var lod_level: String = current.name.substr(lod_index + 3)
		if not lod_level.is_valid_int():
			continue

		var lod_number: int = lod_level.to_int()
		var name: String = current.name.left(lod_index - 1)
		if name in dict:
			dict[name][current] = lod_number
		else:
			dict[name] = { current: lod_number }

	if dict.is_empty():
		return

	for key: String in dict:
		var lods: Dictionary = dict[key]
		# Meshes that have no LOD are also contained in dict.
		if lods.size() <= 1:
			continue

		# Need float for proper divisions.
		# Need to multiply the levels by 2 since a beginning and end is required.
		var max_lod_level: float = (lods.values().max() + 1) * 2.0
		var lod_begin: float
		var lod_end: float
		for instance: GeometryInstance3D in lods:
			lod_begin = lods[instance] * 2.0
			lod_end = (lods[instance] + 1) * 2.0
			instance.visibility_range_begin = ease(lod_begin / max_lod_level, easing) * max_distance
			instance.visibility_range_end = ease(lod_end / max_lod_level, easing) * max_distance
