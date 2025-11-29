This is a repository for sharing various systems and utility scripts I've written for my Godot projects.

> [!IMPORTANT]
> I will not provide support for anything in this repository.
> You may use these scripts under the provided license as you wish.

> [!TIP]
> Some plugins are not useful in or have files not necessary to run
> in an exported game. These are marked by being contained in a folder starting with
> and underscore (_). For example: _editor_only, _icons, etc.  
> You can exclude these folders from your exported game by adding them to your export
> profile's "Filters to exclude files/folders from project" section.
>
> To exclude all of them the pattern "\*/_\*/\*" works.

## Contents

### [Auto HLOD Import](https://github.com/ShellyFrog/godot-stuff/tree/main/addons/shelly_frog/_editor_only/auto_hlod_import)

An [EditorScenePostImportPlugin](https://docs.godotengine.org/en/stable/classes/class_editorscenepostimportplugin.html) that allows automatically assigning [Visibility Ranges](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html) to 3D meshes based on a naming suffix, a maximum distance, and a distribution curve.

### [GDX Texture Atlas Importer](https://github.com/ShellyFrog/godot-stuff/tree/main/addons/shelly_frog/_editor_only/gdx_texture_atlas_import)

An import plugin that allows importing [GDX Texture Packer](https://github.com/crashinvaders/gdx-texture-packer-gui) .atlas files as `AtlasTexture`s automatically.  

### [Input Management](https://github.com/ShellyFrog/godot-stuff/tree/main/addons/shelly_frog/input_management)

A system for handling the concept of "players" for input, allowing assigning devices and remapping input per player.
Additionally contains a script for simulating "echo" events for joypads.
