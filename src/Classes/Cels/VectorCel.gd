class_name VectorCel
extends BaseCel
# A class for the properties of cels in VectorLayers.
# The term "cel" comes from "celluloid" (https://en.wikipedia.org/wiki/Cel).
# The "vshapes" variable stores the cel's content, VectorShapes

var vshapes := [] # Array[VectorBaseShape]

func _init(_vshapes := [], _opacity := 1.0, _image_texture: ImageTexture = null) -> void:
	vshapes = _vshapes

	if _image_texture:
		image_texture = _image_texture
	else:
		# TODO: Can we prevent an extra update_texture when opening files (since it can't be deserialized until it has all cels)
		# TODO: Is it possible to use the viewport texture directly?
		image_texture = ImageTexture.new()
		update_texture()
	opacity = _opacity
	process_test_tools()


func process_test_tools():  # TODO: This method should be removed once integration with actual tools begins
	# Selection Test Loop:
	var prev_mouse_pos := Vector2.ZERO
	while(true):
		await Global.get_tree().process_frame

		if not Global.current_project.frames[Global.current_project.current_frame].cels.has(self):
			continue

		var tmp_transform = Global.canvas.get_canvas_transform().affine_inverse()
		var tmp_position = Global.main_viewport.get_local_mouse_position()
		var mouse_pos = tmp_transform.basis_xform(tmp_position) + tmp_transform.origin

		var selected_index := -1
		for s in vshapes.size():
			if vshapes[s].has_point(mouse_pos):
				selected_index = s
		if selected_index < 0:
			print("Can't select")
			continue
		print("Selected shape ", selected_index)

		if Input.is_key_pressed(KEY_M):
			vshapes[selected_index].pos += mouse_pos - prev_mouse_pos
			vshapes[selected_index].pos = vshapes[selected_index].pos.snapped(Vector2.ONE)
			update_texture()
		if Input.is_action_just_released("copy"):
			var copy = vshapes[selected_index].get_script().new()
			copy.deserialize(vshapes[selected_index].serialize())
			copy.font = vshapes[selected_index].font.duplicate(true)
			vshapes.append(copy)
			update_texture()
		if Input.is_action_just_released("delete"):
			vshapes.remove_at(selected_index)
			update_texture()
		if Input.is_key_pressed(KEY_R):
			vshapes[selected_index].text = str(int(randf_range(100000, 9999999)))
			vshapes[selected_index].color.h = randf_range(0, 1)
			vshapes[selected_index].outline_color.h = randf_range(0, 1)
			vshapes[selected_index].font_size = randf_range(8, 16)
			vshapes[selected_index].outline_size = randf_range(0, 4)
			vshapes[selected_index].antialiased = bool(round(randf_range(0, 1)))
			update_texture()
		prev_mouse_pos = mouse_pos


func get_content():
	return vshapes


func set_content(content, texture: ImageTexture = null) -> void:
	vshapes = content
	if is_instance_valid(texture):
		image_texture = texture
		if Vector2i(image_texture.get_size()) != Global.current_project.size:
			update_texture()
	else:
		update_texture()


func create_empty_content():
	return []


func copy_content():
	var copy_vshapes := []
	for vshape in vshapes:
		var copy = vshape.get_script().new()
		copy.deserialize(vshape.serialize())
	return copy_vshapes


func get_image() -> Image:
	return image_texture.get_image()


func update_texture() -> void:
	if vshapes.is_empty():
		# TODO: Color picker doesn't work when its a tiny image like this. Maybe it can can based on percentage? Or just have to use large full size
		var image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image_texture = ImageTexture.create_from_image(image)
		return
	var start_msec := Time.get_ticks_msec()  # For benchmark

	# TODO: Check if simply creating/setting up a viewport/canvas is slow. It may be worth keeping one around in Global or Project to share.

	var vp := RenderingServer.viewport_create()
	var canvas := RenderingServer.canvas_create()
	RenderingServer.viewport_attach_canvas(vp, canvas)
	RenderingServer.viewport_set_size(vp, Global.current_project.size.x, Global.current_project.size.y)
	RenderingServer.viewport_set_disable_3d(vp, true)
	RenderingServer.viewport_set_active(vp, true)
	RenderingServer.viewport_set_transparent_background(vp, true)

	var ci_rid := RenderingServer.canvas_item_create()
	RenderingServer.viewport_set_canvas_transform(vp, canvas, Transform3D())
	RenderingServer.canvas_item_set_parent(ci_rid, canvas)

	for vshape in vshapes:
		vshape.draw(ci_rid)

	RenderingServer.viewport_set_update_mode(vp, RenderingServer.VIEWPORT_UPDATE_ONCE)
	RenderingServer.force_draw(false)
	var viewport_texture := RenderingServer.texture_2d_get(RenderingServer.viewport_get_texture(vp))
	RenderingServer.free_rid(vp)
	RenderingServer.free_rid(canvas)
	RenderingServer.free_rid(ci_rid)

	# Perhaps texture_set_proxy will allow for faster updates to image_texture?

	# TODO: This should be able to be made faster:
	var shader_effect := ShaderImageEffect.new()
	shader_effect.generate_image(viewport_texture, preload("res://src/Shaders/VectorRenderColorCorrect.gdshader"), {}, Global.current_project.size)

	viewport_texture.convert(Image.FORMAT_RGBA8)
	image_texture.create_from_image(viewport_texture, 0)
	print("VectorCel update time (msec): ", Time.get_ticks_msec() - start_msec)
