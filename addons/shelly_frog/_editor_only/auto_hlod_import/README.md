## Auto HLOD Import

![An example of the import options of the plugin.](https://github.com/ShellyFrog/godot-stuff/blob/main/img/auto_hlod.webp)

An [EditorScenePostImportPlugin](https://docs.godotengine.org/en/stable/classes/class_editorscenepostimportplugin.html) that allows automatically assigning [Visibility Ranges](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html) to 3D meshes based on a naming suffix, a maximum distance, and a distribution curve.

The import options will be available in the import dock of any 3D scene as soon as the plugin is enabled. You will need to re-import any scenes already imported before this plugin was enabled.

To make your meshes compatible with the plugin make sure to suffix the **object names** with the desired LOD like "\<mesh_name\>lod\<number\>". This is **case insensitive**.  
For example:
```
Mesh_LOD0
Mesh_LOD1
Mesh_LOD2
```
or
```
mesh_lod0
mesh_lod1
mesh_lod2
```

In case the first LOD does not have a number but other LOD meshes exist it will be assigned LOD 0 automatically.  
For example with a setup such as:
```
Mesh
Mesh_LOD1
Mesh_LOD2
```
the mesh called "Mesh" will be assigned LOD level 0 automatically.
