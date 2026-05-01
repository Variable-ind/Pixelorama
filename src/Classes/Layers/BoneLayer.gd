class_name BoneLayer
extends GroupLayer

enum { NONE, DISPLACE, ROTATE, EXTEND }
const INTERACTION_DISTANCE: float = 20
const DESELECT_WIDTH: float = 1
const MIN_LENGTH: float = 5
const START_RADIUS: float = 6
const END_RADIUS: float = 4
const WIDTH: float = 2

## Starting point of the gizmo (with zero displacement).
## True gizmo origin is this plus displacement. It's value is relative to canvas, instead of the
## parent.
var gizmo_origin_no_disp := Vector2.ZERO:
	set(value):
		if not gizmo_origin_no_disp.is_equal_approx(value):
			gizmo_origin_no_disp = value
## Gizmo rotation (when local_rotation is zero).
## True gizmo rotation is this plus local_rotation. It's value is relative to canvas, instead of the
## parent.
var gizmo_rotate_origin: float = 0:  ## Unit is Radians
	set(value):
		if not is_equal_approx(value, gizmo_rotate_origin):
			gizmo_rotate_origin = value
## The distance between the starting point of gizmo and it's ending point.
var gizmo_length: int = MIN_LENGTH + 5:
	set(value):
		if not is_equal_approx(value, gizmo_length) and value > int(MIN_LENGTH):
			if value < int(MIN_LENGTH):
				value = int(MIN_LENGTH)
			gizmo_length = value

var enabled := true

var ignore_rotation_hover := false
var modify_mode := NONE
var generation_cache: Dictionary
var rotation_renderer := ShaderImageEffect.new()
var algorithm := DrawingAlgos.nn_shader
var animator := BoneAnimator.new(default_bone_params())

class BoneAnimator:
	extends AnimatableObject

	func _init(_params: Dictionary[String, Variant] = {}) -> void:
		params = _params


static func get_parent_chain(layer) -> Array[BoneLayer]:
	var chain: Array[BoneLayer] = []
	var bone_parent = layer.parent
	while bone_parent != null:
		if bone_parent is BoneLayer:
			chain.push_front(bone_parent)
		bone_parent = bone_parent.parent
	return chain


static func get_parent_bone(layer) -> BoneLayer:
	var bone_parent = layer.parent
	while bone_parent != null:
		if bone_parent is BoneLayer:
			break
		bone_parent = bone_parent.parent
	return bone_parent


static func default_bone_params() -> Dictionary[String, Variant]:
	var data: Dictionary[String, Variant] = {}
	data["local_displacement"] = Vector2.ZERO
	data["local_rotation"] = 0
	return data


func get_end(frame: int = project.current_frame) -> Vector2:
	return Vector2(gizmo_length, 0).rotated(gizmo_rotate_origin + get_net_rotation(frame))


func get_parent_contributions(frame: int = project.current_frame):
	var rotation: float = 0
	var displacement := Vector2.ZERO
	var parent_chain := get_parent_chain(self)
	for parent_bone in parent_chain:
		var params := parent_bone.animator.get_params(frame)
		displacement += params.get("local_displacement", Vector2.ZERO).rotated(rotation)
		rotation += params.get("local_rotation", 0.0)
	return {
		"rotation": rotation,
		"displacement": displacement,
	}


func get_local_displacement(frame: int = project.current_frame) -> Vector2:
	return animator.get_param("local_displacement", frame, Vector2.ZERO)


func set_local_displacement(value: Vector2, frame: int = project.current_frame) -> void:
	animator.set_keyframe("local_displacement", frame, value)


func get_local_rotation(frame: int = project.current_frame) -> float:
	return animator.get_param("local_rotation", frame, 0.0)


func set_local_rotation(value: float, frame: int = project.current_frame) -> void:
	animator.set_keyframe("local_rotation", frame, value)


func get_net_displacement(frame: int = project.current_frame) -> Vector2:
	var p_contributions = get_parent_contributions(frame)
	return (
		animator.get_param(
			"local_displacement", frame, Vector2.ZERO
		).rotated(p_contributions["rotation"])
		+ p_contributions["displacement"]
	)


func get_net_rotation(frame: int = project.current_frame) -> float:
	return get_local_rotation(frame) + get_parent_contributions(frame)["rotation"]


## Converts coordinates that are relative to canvas get converted to position relative to
## gizmo_origin_no_disp.
func rel_to_origin(pos: Vector2) -> Vector2:
	return pos - gizmo_origin_no_disp


## Converts coordinates that are relative to canvas get converted to position relative to
## start point (the bigger circle).
func rel_to_start_point(pos: Vector2, frame: int = project.current_frame) -> Vector2:
	return pos - gizmo_origin_no_disp - get_net_displacement(frame)


## Converts coordinates that are relative to gizmo_origin_no_disp get converted to position relative to
## canvas.
func rel_to_canvas(pos: Vector2) -> Vector2:
	return pos + gizmo_origin_no_disp


func _init(_project: Project, _name := "") -> void:
	super(_project, _name)


# Currently used in serialize()
func get_bone_data(vectors_as_string: bool) -> Dictionary:
	var data := {}
	if vectors_as_string:
		data["gizmo_origin_no_disp"] = var_to_str(gizmo_origin_no_disp)
		data["gizmo_rotate_origin"] = var_to_str(gizmo_rotate_origin)
	else:
		data["gizmo_origin_no_disp"] = gizmo_origin_no_disp
		data["gizmo_rotate_origin"] = gizmo_rotate_origin
	data["gizmo_length"] = gizmo_length
	return data.merged(animator.serialize())


func serialize() -> Dictionary:
	var data := super()
	data["enabled"] = enabled
	data.merge(get_bone_data(true))
	return data


func deserialize(dict: Dictionary) -> void:
	super(dict)
	if dict.has("enabled"):
		enabled = dict.get("enabled", enabled)
	animator.deserialize(dict)


## Returns a new empty [BaseCel]
func new_empty_cel() -> BaseCel:
	return BoneCel.new()


func get_best_origin(frame: Frame) -> Vector2i:
	var used_rect := Rect2i()
	for child_layer in project.layers[index].get_children(false):
		if !child_layer is GroupLayer:
			var cel_rect := frame.cels[child_layer.index].get_image().get_used_rect()
			if cel_rect.has_area():
				used_rect = used_rect.merge(cel_rect) if used_rect.has_area() else cel_rect
	@warning_ignore("integer_division")
	return used_rect.position + (used_rect.size / 2)


## Calculates hover mode of current BoneLayer
func hover_mode(mouse_position: Vector2, camera_zoom) -> int:
	var local_mouse_pos = rel_to_origin(mouse_position)
	if (get_net_displacement()).distance_to(local_mouse_pos) <= INTERACTION_DISTANCE / camera_zoom.x:
		return DISPLACE
	elif (
		(get_net_displacement() + get_end()).distance_to(local_mouse_pos)
		<= INTERACTION_DISTANCE / camera_zoom.x
	):
		if !ignore_rotation_hover:
			return EXTEND
	elif _is_close_to_segment(
		rel_to_start_point(mouse_position),
		INTERACTION_DISTANCE / camera_zoom.x,
		Vector2.ZERO,
		get_end()
	):
		if !ignore_rotation_hover:
			return ROTATE
	return NONE


static func _is_close_to_segment(
	pos: Vector2, detect_distance: float, s1: Vector2, s2: Vector2
) -> bool:
	var test_line := (s2 - s1).rotated(deg_to_rad(90)).normalized()
	var from_a := pos - test_line * detect_distance
	var from_b := pos + test_line * detect_distance
	if Geometry2D.segment_intersects_segment(from_a, from_b, s1, s2):
		return true
	return false


## Overrides


func get_child_bones(recursive: bool) -> Array[BoneLayer]:
	var children: Array[BoneLayer] = []
	if recursive:
		for i in index:
			if is_ancestor_of(project.layers[i]) and project.layers[i] is BoneLayer:
				children.append(project.layers[i])
	else:
		for i in index:
			if project.layers[i].parent == self:
				if project.layers[i] is BoneLayer:
					children.append(project.layers[i])
				elif project.layers[i] is GroupLayer:
					var groups_to_scan = [project.layers[i]]
					while groups_to_scan.size() != 0:
						for child in groups_to_scan.pop_front().get_children(false):
							if child is BoneLayer:
								children.append(child)
							elif child is GroupLayer:
								groups_to_scan.append(child)
	return children


func apply_bone(cel_image: Image, at_frame: int) -> Image:
	if is_edit_mode() or DrawingAlgos.force_bone_mode == DrawingAlgos.BoneRenderMode.EDIT:
		if DrawingAlgos.force_bone_mode != DrawingAlgos.BoneRenderMode.POSE:
			return cel_image
	var frame_angle: float = get_net_rotation(at_frame)
	var frame_start_point: Vector2i = get_net_displacement(at_frame)
	if frame_angle == 0 and frame_start_point == Vector2i.ZERO:
		return cel_image
	var used_region := cel_image.get_used_rect()
	if used_region.size == Vector2i.ZERO:
		return cel_image
	# Imprint on a square for rotation
	# (We are doing this so that the image doesn't get clipped as a result of rotation.)
	var diagonal_length := floori(used_region.size.length())
	if diagonal_length % 2 == 0:
		diagonal_length += 1
	var s_offset: Vector2i = (
		(0.5 * (Vector2i(diagonal_length, diagonal_length) - used_region.size)).floor()
	)
	var square_image = cel_image.get_region(
		Rect2i(used_region.position - s_offset, Vector2i(diagonal_length, diagonal_length))
	)
	# Apply Rotation To this Image
	if frame_angle != 0:
		var transformation_matrix := Transform2D(frame_angle, Vector2.ZERO)
		var rotate_params := {
			"transformation_matrix": transformation_matrix.affine_inverse(),
			"pivot": Vector2(0.5, 0.5),
			"ending_angle": frame_angle,
			"tolerance": 0,
			"preview": false
		}
		# Detects if the rotation is changed for this generation or not
		# (useful if bone is moved around while having some rotation)
		# NOTE: I tried caching entire poses (that remain same) as well. It was faster than this
		# approach but only by a few milliseconds. I don't think straining the memory for only
		# a boost of a few millisec was worth it so i declare this the most optimal approach.
		var cache_key := {"angle": frame_angle, "un_transformed": square_image.get_data()}
		var bone_cel: BoneCel = project.frames[at_frame].cels[index]
		var bone_cache: Dictionary = generation_cache.get_or_add(bone_cel, {})
		if cache_key in bone_cache.keys():
			square_image = bone_cache[cache_key]
		else:
			rotation_renderer.generate_image(
				square_image, algorithm, rotate_params, square_image.get_size(), true, false
			)
			bone_cache.clear()
			bone_cache[cache_key] = square_image
	var gizmo_origin_no_disp_floored: Vector2i = gizmo_origin_no_disp.floor()
	var pivot: Vector2i = gizmo_origin_no_disp_floored
	var bone_start_global: Vector2i = gizmo_origin_no_disp_floored + frame_start_point
	var square_image_start: Vector2i = used_region.position - s_offset
	var global_square_centre: Vector2 = square_image_start + (square_image.get_size() / 2)
	var global_rotated_new_centre = (
		(global_square_centre - Vector2(pivot)).rotated(frame_angle) + Vector2(bone_start_global)
	)
	var new_start: Vector2i = (
		square_image_start + Vector2i((global_rotated_new_centre - global_square_centre).floor())
	)
	cel_image.fill(Color(0, 0, 0, 0))
	cel_image.blit_rect(
		square_image, Rect2i(Vector2.ZERO, square_image.get_size()), Vector2i(new_start)
	)
	return cel_image


func get_layer_type() -> int:
	return Global.LayerTypes.BONE


func set_name_to_default(number: int) -> void:
	name = tr("Bone") + " %s" % number


func is_edit_mode() -> bool:
	# Edit mode is when, if current layer isn't a BoneLayer, or a part of BoneLayer or is
	# BoneLayer but not enabled
	var edit_mode := (
		not enabled
		or (
			not project.layers[project.current_layer] is BoneLayer
			and not BoneLayer.get_parent_bone(project.layers[project.current_layer]) == null
		)
	)
	return edit_mode


func is_blender() -> bool:
	if blend_mode != BlendModes.PASS_THROUGH:
		return true
	else:
		if DrawingAlgos.force_bone_mode == DrawingAlgos.BoneRenderMode.EDIT:
			return false
		elif DrawingAlgos.force_bone_mode == DrawingAlgos.BoneRenderMode.POSE:
			return true
	return false
