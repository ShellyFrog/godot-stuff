@tool
extends EditorImportPlugin

const EXTENSION: String = "atlas"

const GDXAtlas = preload("uid://br4nnudmg5355")

const OPTION_IGNORE_OFFSETS: StringName = &"ignore_offsets"

enum Preset {
	PRESET_DEFAULT,
}


func _get_importer_name():
	return "shellyfrog.gdx_atlas_importer"


func _get_visible_name():
	return "GDX Texture Atlas"


func _get_recognized_extensions():
	return ["atlas"]


func _get_save_extension():
	return "tres"


func _get_resource_type():
	return "Resource"


func _get_preset_count():
	return Preset.size()


func _get_preset_name(preset):
	match preset:
		Preset.PRESET_DEFAULT:
			return "Default"


func _get_import_options(path, preset_index):
	return [
		{
			"name": OPTION_IGNORE_OFFSETS,
			"default_value": false,
		}
	]


func _get_option_visibility(path, option_name, options):
	return true


func _get_import_order():
	return 200


func _get_priority():
	return 1.0


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var base_dir: String = source_file.get_base_dir()
	var file := FileAccess.open(source_file, FileAccess.READ)
	var pages: Dictionary = GDXAtlas.parse(file)
	file.close()

	for page_file_name in pages:
		var page_file: String = base_dir + '/' + page_file_name
		if not ResourceLoader.exists(page_file):
			continue

		var atlas := ResourceLoader.load(page_file) as Texture2D
		if not atlas:
			continue

		var page_name: String = page_file_name.trim_suffix('.' + page_file_name.get_extension())
		var texture_dir: String = base_dir + '/' + page_name
		var dir_error: Error = DirAccess.make_dir_recursive_absolute(texture_dir)
		if dir_error != OK:
			push_error("Failed to create GDX Atlas directory: %s" % error_string(dir_error))
			return dir_error

		for region in pages[page_file_name]:
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = atlas
			atlas_texture.region = region.get("bounds", Rect2())
			if options[OPTION_IGNORE_OFFSETS] == false:
				var offset: Rect2 = region.get("offsets", Rect2())
				if offset != Rect2():
					var bottom_right: Vector2 = offset.size - atlas_texture.region.size
					atlas_texture.margin = Rect2(offset.position.x, bottom_right.y - offset.position.y, bottom_right.x, bottom_right.y)
			var atlas_texture_path: String = texture_dir + '/' + region[GDXAtlas.REGION_NAME_KEY] + ".tres"
			ResourceSaver.save(atlas_texture, atlas_texture_path)
			gen_files.push_back(atlas_texture_path)

		for resource in ResourceLoader.list_directory(texture_dir):
			var full_path: String = texture_dir + '/' + resource
			if gen_files.has(full_path):
				continue
			var delete_error: Error = DirAccess.remove_absolute(full_path)
			if delete_error != OK:
				push_error("Failed to delete old GDX Atlas Texture (%s): %s" % [full_path, error_string(delete_error)])

	EditorInterface.get_resource_filesystem().scan_sources()

	return ResourceSaver.save(Resource.new(), "%s.%s" % [save_path, _get_save_extension()])
