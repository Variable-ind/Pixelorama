class_name BoneLayer
extends GroupLayer

enum { NONE, DISPLACE, ROTATE, EXTEND }
const INTERACTION_DISTANCE: float = 20
const DESELECT_WIDTH: float = 1
const MIN_LENGTH: float = 5
const START_RADIUS: float = 6
const END_RADIUS: float = 4
const WIDTH: float = 2

# Variables set using serialize() they are here just to assist in calculations
var gizmo_origin := Vector2.ZERO:
	set(value):
		if not gizmo_origin.is_equal_approx(value):
			gizmo_origin = value
var gizmo_rotate_origin: float = 0:  ## Unit is Radians
	set(value):
		if not is_equal_approx(value, gizmo_rotate_origin):
			gizmo_rotate_origin = value
var start_point := Vector2.ZERO:  ## This is relative to the gizmo_origin
	set(value):
		if not start_point.is_equal_approx(value):
			var diff = value - start_point
			start_point = value
			if should_update_children:
				update_children("start_point", diff)
var bone_rotation: float = 0:  ## This is relative to the gizmo_rotate_origin (Radians)
	set(value):
		if not is_equal_approx(value, bone_rotation):
			value = wrapf(value, -PI, PI)
			var diff = value - bone_rotation
			bone_rotation = value
			if should_update_children:
				update_children("bone_rotation", diff)
var gizmo_length: int = MIN_LENGTH + 5:
	set(value):
		if not is_equal_approx(value, gizmo_length) and value > int(MIN_LENGTH):
			if value < int(MIN_LENGTH):
				value = int(MIN_LENGTH)
			gizmo_length = value

var associated_layer: BoneLayer  ## only used in update_children()
var should_update_children := true
var should_make_keyframes := true

# Properties determined using above variables
var end_point: Vector2:  ## This is relative to the start_point
	get():
		return Vector2(gizmo_length, 0).rotated(gizmo_rotate_origin + bone_rotation)

var enabled := true

var ignore_rotation_hover := false
var modify_mode := NONE
var generation_cache: Dictionary
var rotation_renderer := ShaderImageEffect.new()
var algorithm := DrawingAlgos.nn_shader

## A Dictionary containing another Dictionary that
## maps the frame indices (int) to another Dictionary of value, trans, ease,
## and a layer-scope unique ID.
## Example:
## [codeblock]
##{
##	"gizmo_origin":
##	{
##		0: {id: 0, "value": Vector2(0, 0), "trans": 0, "ease": 2},
##		10: {id: 1, "value": Vector2(64, 64), "trans": 1, "ease": 3},
##	},
##	"gizmo_rotate_origin":
##	{
##		1: {id: 2, "value": false, "trans": 0, "ease": 0},
##		3: {id: 3, "value": true, "trans": 0, "ease": 0},
##		10: {id: 4, "value": false, "trans": 0, "ease": 0},
##	},
##}
## [/codeblock]
var animated_params: Dictionary[String, Dictionary] = {}


## Converts coordinates that are relative to canvas get converted to position relative to
## gizmo_origin.
func rel_to_origin(pos: Vector2) -> Vector2:
	return pos - gizmo_origin


## Converts coordinates that are relative to canvas get converted to position relative to
## start point (the bigger circle).
func rel_to_start_point(pos: Vector2) -> Vector2:
	return pos - gizmo_origin - start_point


## Converts coordinates that are relative to gizmo_origin get converted to position relative to
## canvas.
func rel_to_canvas(pos: Vector2, is_rel_to_start_point := false) -> Vector2:
	var diff = start_point if is_rel_to_start_point else Vector2.ZERO
	return pos + gizmo_origin + diff


func _init(_project: Project, _name := "") -> void:
	super(_project, _name)


func set_keyframe(
	param_name: String,
	frame_index: int,
	value: Variant,
	trans := Tween.TRANS_LINEAR,
	ease_type := Tween.EASE_IN
) -> void:
	if not animated_params.has(param_name):
		animated_params[param_name] = {}
	var id := next_keyframe_id
	animated_params[param_name][frame_index] = {
		"id": id, "value": value, "trans": trans, "ease": ease_type
	}
	next_keyframe_id += 1


func repopulate_variables() -> void:
	if project == Global.current_project:
		should_make_keyframes = false
		should_update_children = false
		set_bone_data(get_params(project.current_frame))
		should_make_keyframes = true
		should_update_children = true


func get_params(frame_index: int) -> Dictionary:
	#var to_return := get_bone_data(false).duplicate()
	var to_return := default_bone_params()
	for param in animated_params:
		var animated_properties := animated_params[param]  # Dictionary[int, Dictionary]
		if animated_properties.has(frame_index):
			# If the frame index exists in the properties, get that.
			to_return[param] = animated_properties[frame_index].get("value", to_return[param])
		else:
			if animated_properties.size() == 0:
				continue
			# If it doesn't exist, interpolate.
			var frame_edges := find_frame_edges(frame_index, animated_properties)
			var min_params: Dictionary = animated_properties[frame_edges[0]]
			var max_params: Dictionary = animated_properties[frame_edges[1]]
			var min_value = min_params.get("value", to_return[param])
			print(min_value)
			var max_value = max_params.get("value", to_return[param])
			if not is_interpolatable_type(min_value):
				to_return[param] = max_value
				continue
			var elapsed := frame_index - frame_edges[0]
			var delta = max_value - min_value
			var duration := frame_edges[1] - frame_edges[0]
			var trans_type: int = min_params.get("trans", Tween.TRANS_LINEAR)
			if trans_type == Tween.TRANS_SPRING + 1:
				to_return[param] = min_value
				continue
			var ease_type: Tween.EaseType = min_params.get("ease", Tween.EASE_IN)
			to_return[param] = Tween.interpolate_value(
				min_value, delta, elapsed, duration, trans_type, ease_type
			)
	return to_return


func default_bone_params() -> Dictionary:
	var data := {}
	data["start_point"] = Vector2.ZERO
	data["bone_rotation"] = 0
	return data


func find_frame_edges(frame_index: int, animated_properties: Dictionary) -> Array[int]:
	var param_keys := animated_properties.keys()
	if param_keys.size() == 1:
		return [param_keys[0], param_keys[0]]
	param_keys.sort()
	var minimum: int = param_keys[0]
	var maximum: int = param_keys[-1]
	for key in param_keys:
		if key > minimum and key <= frame_index:
			minimum = key
		if key < maximum and key >= frame_index:
			maximum = key
	return [minimum, maximum]


static func is_interpolatable_type(value: Variant) -> bool:
	match typeof(value):
		TYPE_INT, TYPE_FLOAT, TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I:
			return true
		TYPE_VECTOR4, TYPE_VECTOR4I, TYPE_COLOR, TYPE_QUATERNION:
			return true
		_:
			return false


func get_bone_data(vectors_as_string: bool) -> Dictionary:
	var data := {}
	if vectors_as_string:
		data["gizmo_origin"] = var_to_str(gizmo_origin)
		data["gizmo_rotate_origin"] = var_to_str(gizmo_rotate_origin)
		data["start_point"] = var_to_str(start_point)
	else:
		data["gizmo_origin"] = gizmo_origin
		data["gizmo_rotate_origin"] = gizmo_rotate_origin
		data["start_point"] = start_point
	data["bone_rotation"] = bone_rotation
	data["gizmo_length"] = gizmo_length
	return data


func set_bone_data(data: Dictionary) -> void:
	# These need conversion before setting
	if typeof(data.get("gizmo_origin", gizmo_origin)) == TYPE_STRING:
		data["gizmo_origin"] = str_to_var(data.get("gizmo_origin", var_to_str(gizmo_origin)))

	if typeof(data.get("start_point", start_point)) == TYPE_STRING:
		data["start_point"] = str_to_var(data.get("start_point", start_point))

	if typeof(data.get("gizmo_rotate_origin", gizmo_rotate_origin)) == TYPE_STRING:
		data["gizmo_rotate_origin"] = str_to_var(
			data.get("gizmo_rotate_origin", gizmo_rotate_origin)
		)
	gizmo_origin = data.get("gizmo_origin", gizmo_origin)
	gizmo_rotate_origin = data.get("gizmo_rotate_origin", gizmo_rotate_origin)
	start_point = data.get("start_point", start_point)
	bone_rotation = data.get("bone_rotation", bone_rotation)
	gizmo_length = data.get("gizmo_length", gizmo_length)


func serialize() -> Dictionary:
	var data := super()
	data["enabled"] = enabled
	data["animated_params"] = var_to_str(animated_params)
	data.merge(get_bone_data(true))
	return data


func deserialize(dict: Dictionary) -> void:
	super(dict)
	if dict.has("enabled"):
		enabled = dict.get("enabled", enabled)
	if dict.has("animated_params"):
		animated_params = str_to_var(dict["animated_params"])


## Returns a new empty [BaseCel]
func new_empty_cel() -> BaseCel:
	return BoneCel.new()


static func get_parent_bone(layer) -> BoneLayer:
	var bone_parent = layer.parent
	while bone_parent != null:
		if bone_parent is BoneLayer:
			break
		bone_parent = bone_parent.parent
	return bone_parent


func get_best_origin(frame: Frame) -> Vector2i:
	var used_rect := Rect2i()
	for child_layer in project.layers[index].get_children(false):
		if !child_layer is GroupLayer:
			var cel_rect := frame.cels[child_layer.index].get_image().get_used_rect()
			if cel_rect.has_area():
				used_rect = used_rect.merge(cel_rect) if used_rect.has_area() else cel_rect
	@warning_ignore("integer_division")
	return used_rect.position + (used_rect.size / 2)


func get_current_bone_cel(frame_idx := Global.current_project.current_frame) -> BoneCel:
	return Global.current_project.frames[frame_idx].cels[index]


## Calculates hover mode of current BoneLayer
func hover_mode(mouse_position: Vector2, camera_zoom) -> int:
	var local_mouse_pos = rel_to_origin(mouse_position)
	if (start_point).distance_to(local_mouse_pos) <= INTERACTION_DISTANCE / camera_zoom.x:
		return DISPLACE
	elif (
		(start_point + end_point).distance_to(local_mouse_pos)
		<= INTERACTION_DISTANCE / camera_zoom.x
	):
		if !ignore_rotation_hover:
			return EXTEND
	elif _is_close_to_segment(
		rel_to_start_point(mouse_position),
		INTERACTION_DISTANCE / camera_zoom.x,
		Vector2.ZERO,
		end_point
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


func apply_bone(cel_image: Image, at_frame: Frame) -> Image:
	if is_edit_mode() or DrawingAlgos.force_bone_mode == DrawingAlgos.BoneRenderMode.EDIT:
		if DrawingAlgos.force_bone_mode != DrawingAlgos.BoneRenderMode.POSE:
			return cel_image

	var angle: float = bone_rotation
	if angle == 0 and start_point == Vector2.ZERO:
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
	if angle != 0:
		var transformation_matrix := Transform2D(angle, Vector2.ZERO)
		var rotate_params := {
			"transformation_matrix": transformation_matrix.affine_inverse(),
			"pivot": Vector2(0.5, 0.5),
			"ending_angle": angle,
			"tolerance": 0,
			"preview": false
		}
		# Detects if the rotation is changed for this generation or not
		# (useful if bone is moved around while having some rotation)
		# NOTE: I tried caching entire poses (that remain same) as well. It was faster than this
		# approach but only by a few milliseconds. I don't think straining the memory for only
		# a boost of a few millisec was worth it so i declare this the most optimal approach.
		var cache_key := {"angle": angle, "un_transformed": square_image.get_data()}
		var bone_cel: BoneCel = at_frame.cels[index]
		var bone_cache: Dictionary = generation_cache.get_or_add(bone_cel, {})
		if cache_key in bone_cache.keys():
			square_image = bone_cache[cache_key]
		else:
			rotation_renderer.generate_image(
				square_image, algorithm, rotate_params, square_image.get_size(), true, false
			)
			bone_cache.clear()
			bone_cache[cache_key] = square_image
	var gizmo_origin_floored: Vector2i = gizmo_origin.floor()
	var pivot: Vector2i = gizmo_origin_floored
	var bone_start_global: Vector2i = gizmo_origin_floored + Vector2i(start_point)
	var square_image_start: Vector2i = used_region.position - s_offset
	var global_square_centre: Vector2 = square_image_start + (square_image.get_size() / 2)
	var global_rotated_new_centre = (
		(global_square_centre - Vector2(pivot)).rotated(angle) + Vector2(bone_start_global)
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


# NOTE: This is a recursive function
func update_children(property: String, diff):
	if not is_instance_valid(project):
		return
	#if should_make_keyframes and self == Global.canvas.skeleton.selected_bone:
		#set_keyframe(property, project.current_frame, get(property))
	## update first child (This will trigger a chain process)
	for child_bone in get_child_bones(false):
		if child_bone.get_layer_type() == Global.LayerTypes.BONE:
			child_bone.set(property, child_bone.get(property) + diff)
			if should_make_keyframes:
				child_bone.set_keyframe(property, project.current_frame, child_bone.get(property))
			if property == "bone_rotation":
				var parent_bone: BoneLayer = BoneLayer.get_parent_bone(child_bone)
				if parent_bone:
					var displacement := parent_bone.rel_to_start_point(
						child_bone.rel_to_canvas(child_bone.start_point)
					)
					displacement = displacement.rotated(diff)
					child_bone.start_point = child_bone.rel_to_origin(
						parent_bone.rel_to_canvas(start_point) + displacement
					)
					if should_make_keyframes:
						child_bone.set_keyframe(
							"bone_rotation", project.current_frame, child_bone.get(property)
						)
