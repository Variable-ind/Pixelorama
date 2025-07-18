class_name GroupLayer
extends BaseLayer
## A class for group layer properties

var expanded := true
var _group_cache: Dictionary
var _cache_texture_data: Array[PackedByteArray]
var _blend_generator := ShaderImageEffect.new()


func _init(_project: Project, _name := "") -> void:
	project = _project
	name = _name
	blend_mode = BlendModes.PASS_THROUGH


## Blends all of the images of children layer of the group layer into a single image.
func blend_children(frame: Frame, origin := Vector2i.ZERO, apply_effects := true) -> Image:
	var image := ImageExtended.create_custom(
		project.size.x, project.size.y, false, project.get_image_format(), project.is_indexed()
	)
	var children := get_children(false)
	if children.size() <= 0:
		return image
	var textures: Array[Image] = []
	_cache_texture_data.clear()
	var metadata_image := Image.create(children.size(), 4, false, Image.FORMAT_RGF)
	# Corresponding to the index of texture in textures. This is not the layer index
	var current_metadata_index := 0
	for i in children.size():
		var layer := children[i]
		if layer is GroupLayer:
			current_metadata_index = _blend_child_group(
				image,
				layer,
				frame,
				textures,
				metadata_image,
				current_metadata_index,
				origin,
				apply_effects
			)
			# NOTE: incrementation of current_metadata_index is done internally in
			# _blend_child_group(), so we don't have to use current_metadata_index += 1 here
		else:
			_include_child_in_blending(
				image,
				layer,
				frame,
				textures,
				metadata_image,
				current_metadata_index,
				origin,
				apply_effects
			)
			current_metadata_index += 1

	if DisplayServer.get_name() != "headless" and textures.size() > 0:
		var texture_array := Texture2DArray.new()
		texture_array.create_from_images(textures)
		var params := {
			"layers": texture_array,
			"metadata": ImageTexture.create_from_image(metadata_image),
			"origin_x_positive": origin.x > 0,
			"origin_y_positive": origin.y > 0,
		}
		var c_key := [_cache_texture_data, metadata_image.get_data(), origin.x > 0, origin.y > 0]
		if _group_cache.has(c_key):
			# Don't waste time re-generating for groups that have remained unchanged
			var cache_image = Image.create_from_data(
				project.size.x,
				project.size.y,
				false,
				project.get_image_format(),
				_group_cache[c_key]
			)
			image.blit_rect(
				cache_image, Rect2i(Vector2i.ZERO, cache_image.get_size()), Vector2i.ZERO
			)
		else:
			_group_cache.clear()
			_blend_generator.generate_image(
				image, DrawingAlgos.blend_layers_shader, params, project.size, true, false
			)
			_group_cache[c_key] = image.get_data()
		if apply_effects:
			image = display_effects(frame.cels[index], image)
	return image


func _include_child_in_blending(
	image: ImageExtended,
	layer: BaseLayer,
	frame: Frame,
	textures: Array[Image],
	metadata_image: Image,
	i: int,
	origin: Vector2i,
	apply_effects: bool
) -> void:
	var cel := frame.cels[layer.index]
	if DisplayServer.get_name() == "headless":
		DrawingAlgos.blend_layers_headless(image, project, layer, cel, origin)
	else:
		var cel_image: Image
		if apply_effects:
			cel_image = layer.display_effects(cel)
		else:
			cel_image = cel.get_image()
		textures.append(cel_image)
		_cache_texture_data.append(cel_image.get_data())
		DrawingAlgos.set_layer_metadata_image(layer, cel, metadata_image, i)
		if origin != Vector2i.ZERO:
			# Only used as a preview for the move tool, when used on a group's children
			var test_array := [project.frames.find(frame), project.layers.find(layer)]
			if test_array in project.selected_cels:
				var origin_fixed := Vector2(origin).abs() / Vector2(cel_image.get_size())
				metadata_image.set_pixel(i, 2, Color(origin_fixed.x, origin_fixed.y, 0.0, 0.0))


## Include a child group in the blending process.
## If the child group is set to pass through mode, loop through its children
## and include them as separate images, instead of blending them all together.
## Gets called recursively if the child group has children groups of its own,
## and they are also set to pass through mode.
func _blend_child_group(
	image: ImageExtended,
	layer: BaseLayer,
	frame: Frame,
	textures: Array[Image],
	metadata_image: Image,
	i: int,
	origin: Vector2i,
	apply_effects: bool
) -> int:
	var new_i := i
	var blend_rect := Rect2i(Vector2i.ZERO, project.size)
	var cel := frame.cels[layer.index]
	if layer.blend_mode == BlendModes.PASS_THROUGH:
		var children := layer.get_children(false)
		for j in children.size():
			var child := children[j]
			if child is GroupLayer:
				new_i = _blend_child_group(
					image, child, frame, textures, metadata_image, new_i, origin, apply_effects
				)
			else:
				metadata_image.crop(metadata_image.get_width() + 1, metadata_image.get_height())
				_include_child_in_blending(
					image, child, frame, textures, metadata_image, new_i, origin, apply_effects
				)
				new_i += 1
	else:
		var blended_children := (layer as GroupLayer).blend_children(frame, origin)
		if DisplayServer.get_name() == "headless":
			image.blend_rect(blended_children, blend_rect, origin)
		else:
			textures.append(blended_children)
			_cache_texture_data.append(blended_children.get_data())
			DrawingAlgos.set_layer_metadata_image(layer, cel, metadata_image, i)
		new_i += 1
	return new_i


# Overridden Methods:


func serialize() -> Dictionary:
	var data := super.serialize()
	data["type"] = get_layer_type()
	data["expanded"] = expanded
	return data


func deserialize(dict: Dictionary) -> void:
	super.deserialize(dict)
	expanded = dict.expanded


func get_layer_type() -> int:
	return Global.LayerTypes.GROUP


func new_empty_cel() -> BaseCel:
	return GroupCel.new()


func set_name_to_default(number: int) -> void:
	name = tr("Group") + " %s" % number


func accepts_child(_layer: BaseLayer) -> bool:
	return true


func is_blender() -> bool:
	return blend_mode != BlendModes.PASS_THROUGH
