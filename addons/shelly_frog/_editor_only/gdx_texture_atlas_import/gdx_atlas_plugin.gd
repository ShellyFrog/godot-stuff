@tool
extends EditorPlugin

var importer: EditorImportPlugin


func _enter_tree():
	importer = preload("uid://b8xr74q7kbbh").new()
	add_import_plugin(importer)
	pass


func _exit_tree():
	remove_import_plugin(importer)
	importer = null
