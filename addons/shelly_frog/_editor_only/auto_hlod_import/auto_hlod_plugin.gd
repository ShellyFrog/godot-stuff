@tool
extends EditorPlugin

var importer: EditorScenePostImportPlugin


func _enter_tree():
	importer = preload("uid://bd75ppjgthlkn").new()
	add_scene_post_import_plugin(importer)


func _exit_tree():
	remove_scene_post_import_plugin(importer)
	importer = null
