class_name BoneCel
extends GroupCel
## A class for the properties of cels in GroupLayers.
## The term "cel" comes from "celluloid" (https://en.wikipedia.org/wiki/Cel).

enum {NONE, DISPLACE, ROTATE, SCALE}  ## I planned to add scaling too but decided to give up

## This class is used/created to perform calculations
const InteractionDistance = 20
const MIN_LENGTH: float = 10
const START_RADIUS: float = 6
const END_RADIUS: float = 4
const WIDTH: float = 2
const DESELECT_WIDTH: float = 1

## Starting point of the gizmo (with zero displacement).
## True gizmo origin is this plus displacement. It's value is relative to canvas, instead of the
## parent.
var gizmo_origin_no_disp: Vector2:
	set(value):
		if value != gizmo_origin_no_disp:
			var diff = value - gizmo_origin_no_disp
			gizmo_origin_no_disp = value
			update_children("gizmo_origin_no_disp", false, diff)
## Gizmo rotation (when local_rotation is zero).
## True gizmo rotation is this plus local_rotation. It's value is relative to canvas, instead of the
## parent.
var gizmo_rotate_origin: float = 0:  ## Unit is Radians
	set(value):
		if value != gizmo_rotate_origin:
			var diff = value - gizmo_rotate_origin
			gizmo_rotate_origin = value
			update_children("gizmo_rotate_origin", false, diff)
## The distance between the starting point of gizmo and it's ending point.
var gizmo_length: int:
	set(value):
		if gizmo_length != value and value > int(MIN_LENGTH):
			var diff = value - gizmo_length
			if value < int(MIN_LENGTH):
				value = int(MIN_LENGTH)
				diff = 0
			gizmo_length = value
			update_children("gizmo_length", false, diff)

## This is the displacement of bone without parent contributions.
## It's value is relative to gizmo_origin_no_disp
var local_displacement: Vector2:
	set(value):
		if value != local_displacement:
			var diff = value - local_displacement
			local_displacement = value
			update_children("net_parent_displacement", true, diff)

## Set through local_displacement variable. Do cot change it manually.
## This is the parent contributions in the displacement of bone.
## It's value is relative to gizmo_origin_no_disp
var net_parent_displacement: Vector2:
	set(value):
		if value != net_parent_displacement:
			var diff = value - net_parent_displacement
			net_parent_displacement = value
			update_children("net_parent_displacement", true, diff)

## This is the net rotation, and includes contribution of all it's parents.
## It's value is relative to gizmo_rotate_origin (Radians)
var local_rotation: float = 0:
	set(value):
		if value != local_rotation:
			var diff = value - local_rotation
			local_rotation = value
			update_children("net_parent_rotation", true, diff)

## Set through local_rotation variable. Do cot change it manually.
## This is the parent contributions in the rotation of bone.
## It's value is relative to gizmo_origin_no_disp
var net_parent_rotation: float = 0:
	set(value):
		if value != net_parent_rotation:
			var diff = value - net_parent_rotation
			net_parent_rotation = value
			update_children("net_parent_rotation", true, diff)

var modify_mode := NONE
var ignore_rotation_hover := false


func _init(_opacity := 1.0) -> void:
	opacity = _opacity
	image_texture = ImageTexture.new()


func get_class_name() -> String:
	return "BoneCel"


static func generate_empty_data(
	cel_bone_name := "Invalid Name", cel_parent_bone_name := "Invalid Parent"
) -> Dictionary:
	# Make sure the name/types are the same as the variable names/types
	return {
		"bone_name": cel_bone_name,
		"parent_bone_name": cel_parent_bone_name,
		"gizmo_origin_no_disp": Vector2.ZERO,
		"gizmo_rotate_origin": 0,
		"start_point": Vector2.ZERO,
		"local_rotation": 0,
		"gizmo_length": MIN_LENGTH,
	}


func deserialize(data: Dictionary) -> void:
	var reference_data = generate_empty_data()
	for key in reference_data.keys():
		if get(key) != data.get(key, reference_data[key]):
			set(key, data.get(key, reference_data[key]))


func hover_mode(mouse_position: Vector2, camera_zoom) -> int:
	var local_mouse_pos = rel_to_origin(mouse_position)
	if (get_net_displacement()).distance_to(local_mouse_pos) <= InteractionDistance / camera_zoom.x:
		return DISPLACE
	elif (
		(get_net_displacement() + get_end()).distance_to(local_mouse_pos)
		<= InteractionDistance / camera_zoom.x
	):
		if !ignore_rotation_hover:
			return SCALE
	elif is_close_to_segment(
		rel_to_start_point(mouse_position),
		InteractionDistance / camera_zoom.x,
		Vector2.ZERO, get_end()
	):
		if !ignore_rotation_hover:
			return ROTATE
	return NONE


static func is_close_to_segment(
	pos: Vector2, detect_distance: float, s1: Vector2, s2: Vector2
) -> bool:
	var test_line := (s2 - s1).rotated(deg_to_rad(90)).normalized()
	var from_a := pos - test_line * detect_distance
	var from_b := pos + test_line * detect_distance
	if Geometry2D.segment_intersects_segment(from_a, from_b, s1, s2):
		return true
	return false


func get_end() -> Vector2:
	return Vector2(gizmo_length, 0).rotated(gizmo_rotate_origin + local_rotation)


func get_net_displacement() -> Vector2:
	return local_displacement + net_parent_displacement


func get_net_rotation() -> float:
	return local_rotation + net_parent_rotation


func rel_to_origin(pos: Vector2) -> Vector2:
	return pos - gizmo_origin_no_disp


func rel_to_start_point(pos: Vector2) -> Vector2:
	return pos - gizmo_origin_no_disp - get_net_displacement()


func rel_to_global(pos: Vector2) -> Vector2:
	return pos + gizmo_origin_no_disp


func update_children(property: String, should_propagate: bool, diff):
	var project = Global.current_project
	var layer: BoneLayer = project.layers[project.current_layer]
	if not is_instance_valid(project):
		return
	if !should_propagate:
		# If ignore_render_once is true this probably means we are in the process of modifying
		# "Individual" properties of the bone and don't want them to propagate down the
		# chain.
		return
	## update first child (This will trigger a chain process)
	for child_layer in layer.get_children(false):
		if child_layer.get_layer_type() == Global.LayerTypes.BONE:
			var bone_cel: BoneCel = project.frames[project.current_frame].cels[child_layer.index]
			if bone_cel.get(property) == null:  # Should always be false
				print("A Potential Bug has occured while updating child layers")
				continue
			bone_cel.set(property, bone_cel.get(property) + diff)
			if property == "net_parent_rotation":
				# Check how much displacement is covered by the bone cel relative to parent
				# and rotate it according to parent's new rotation.
				var disp_rel_to_parent := rel_to_start_point(
					bone_cel.rel_to_global(bone_cel.net_parent_displacement)
				)
				disp_rel_to_parent = disp_rel_to_parent.rotated(diff)
				bone_cel.net_parent_displacement = bone_cel.rel_to_origin(
					rel_to_global(net_parent_displacement) + disp_rel_to_parent
				)
