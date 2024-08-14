class_name VectorCel
extends BaseCel

signal selected_object(object: Cel3DObject)
signal scene_property_changed
signal objects_changed

var size: Vector2i  ## Size of the image rendered by the cel.
## Keys are the ids of all [Cel3DObject]'s present in the scene, and their corresponding values
## point to a [Dictionary] containing the properties of that [Cel3DObject].
var object_properties := {}
## The currently selected [Cel3DObject].
var selected: Cel3DObject = null:
	set(value):
		if value == selected:
			return
		if is_instance_valid(selected):  # Unselect previous object if we selected something else
			selected.deselect()
		selected = value
		if is_instance_valid(selected):  # Select new object
			selected.select()
		selected_object.emit(value)
var current_object_id := 0  ## Its value never decreases.


## Class Constructor (used as [code]Cel3D.new(size, from_pxo, object_prop, scene_prop)[/code])
func _init(_size: Vector2i, from_pxo := false, _object_prop := {}, _scene_prop := {}) -> void:
	size = _size
	object_properties = _object_prop
	_add_nodes()
	if not from_pxo:
		if object_properties.is_empty():
			var transform := Transform3D()
			transform.origin = Vector3(-2.5, 0, 0)
			object_properties[0] = {"type": Cel3DObject.Type.DIR_LIGHT, "transform": transform}
			_add_object_node(0)
		current_object_id = object_properties.size()


func _add_nodes() -> void:
	var world := World3D.new()
	world.environment = Environment.new()
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	for object in object_properties:
		_add_object_node(object)
	image_texture #= viewport.get_texture()


func _get_image_texture() -> Texture2D:
	return image_texture


func _update_objects_transform(id: int) -> void:  # Called by undo/redo
	var properties: Dictionary = object_properties[id]
	var object := get_object_from_id(id)
	if not object:
		print("Object with id %s not found" % id)
		return
	object.deserialize(properties)


func get_object_from_id(id: int) -> Cel3DObject:
	#for child in parent_node.get_children():
		#if not child is Cel3DObject:
			#continue
		#if child.id == id:
			#return child
	return null


func size_changed(new_size: Vector2i) -> void:
	size = new_size
	#viewport.size = size
	#image_texture = viewport.get_texture()


func _add_object_node(id: int) -> void:
	pass
	#if not object_properties.has(id):
		#print("Object id not found.")
		#return
	#var node3d := Cel3DObject.new()
	#node3d.id = id
	#node3d.cel = self
	#parent_node.add_child(node3d)
	#if object_properties[id].has("id"):
		#node3d.deserialize(object_properties[id])
	#else:
		#if object_properties[id].has("transform"):
			#node3d.transform = object_properties[id]["transform"]
		#if object_properties[id].has("file_path"):
			#node3d.file_path = object_properties[id]["file_path"]
		#if object_properties[id].has("type"):
			#node3d.type = object_properties[id]["type"]
		#object_properties[id] = node3d.serialize()
	#objects_changed.emit()


func _remove_object_node(id: int) -> void:  ## Called by undo/redo
	return
	#var object := get_object_from_id(id)
	#if is_instance_valid(object):
		#if selected == object:
			#selected = null
		#object.queue_free()
	#objects_changed.emit()


# Overridden methods


func get_image() -> Image:
	return
	#return viewport.get_texture().get_image()


func serialize() -> Dictionary:
	var dict := super.serialize()
	var object_properties_str := {}
	for prop in object_properties:
		object_properties_str[prop] = var_to_str(object_properties[prop])
	dict["object_properties"] = object_properties_str
	return dict


func deserialize(dict: Dictionary) -> void:
	super.deserialize(dict)
	var objects_copy_str: Dictionary = dict["object_properties"]
	for object_id_as_str in objects_copy_str:
		if typeof(object_id_as_str) != TYPE_STRING:  # failsafe in case something has gone wrong
			return
		var id := int(object_id_as_str)
		if current_object_id < id:
			current_object_id = id
		object_properties[id] = str_to_var(objects_copy_str[object_id_as_str])
	current_object_id += 1
	for object in object_properties:
		_add_object_node(object)


func on_remove() -> void:
	return
	#if is_instance_valid(viewport):
		#viewport.queue_free()


func get_class_name() -> String:
	return "VectorCel"
