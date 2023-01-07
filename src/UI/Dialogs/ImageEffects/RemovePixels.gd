extends ImageEffect

onready var pixel_condition_container = $"%PixelConditionContainer"


func set_nodes() -> void:
	preview = $VBoxContainer/AspectRatioContainer/Preview
	selection_checkbox = $VBoxContainer/OptionsContainer/HBoxContainer/SelectionCheckBox
	affect_option_button = $VBoxContainer/OptionsContainer/HBoxContainer/AffectOptionButton


func commit_action(cel: Image, project: Project = Global.current_project) -> void:
	_remove_pixels(cel, selection_checkbox.pressed, project)


func _on_AddCondition_pressed():
	var condition = preload("res://src/UI/Nodes/PixelCondition.tscn").instance()
	pixel_condition_container.add_child(condition)
	condition.connect("changed", self, "_on_conditions_updated")
	update_preview()


func _on_conditions_updated():
	update_preview()


func _remove_pixels(cel: Image, affect_selection: bool, project: Project) -> void:
	if !(affect_selection and project.has_selection):
		for condition in pixel_condition_container.get_children():
			apply_condition(cel, condition)
	else:
		# Create a temporary image that only has the selected pixels in it
		var selected := Image.new()
		var rectangle: Rect2 = Global.canvas.selection.big_bounding_rectangle
		if project != Global.current_project:
			rectangle = project.selection_map.get_used_rect()
		selected = cel.get_rect(rectangle)
		selected.lock()
		cel.lock()
		for x in selected.get_width():
			for y in selected.get_height():
				var pos := Vector2(x, y)
				var cel_pos := pos + rectangle.position
				if project.can_pixel_get_drawn(cel_pos):
					cel.set_pixelv(cel_pos, Color(0, 0, 0, 0))
				else:
					selected.set_pixelv(pos, Color(0, 0, 0, 0))

		selected.unlock()

		for condition in pixel_condition_container.get_children():
			apply_condition(selected, condition)
		cel.blend_rect(selected, Rect2(Vector2.ZERO, selected.get_size()), rectangle.position)


func apply_condition(image :Image, condition):
	var to_remove = []
	for x in image.get_size().x:
		for y in image.get_size().y:
			if condition.is_satisfied(image, Vector2(x, y)):
				if !Vector2(x, y) in to_remove:
					to_remove.append(Vector2(x, y))
				continue
	for point in to_remove:
		image.lock()
		image.set_pixelv(point, Color(0,0,0,0))
		image.unlock()
	return image


func _commit_undo(action: String, undo_data: Dictionary, project: Project) -> void:
	var redo_data := _get_undo_data(project)
	project.undos += 1
	project.undo_redo.create_action(action)

	for image in redo_data:
		if not image is Image:
			continue
		project.undo_redo.add_do_property(image, "data", redo_data[image])
		image.unlock()
	for image in undo_data:
		if not image is Image:
			continue
		project.undo_redo.add_undo_property(image, "data", undo_data[image])
	project.undo_redo.add_do_method(Global, "undo_or_redo", false, -1, -1, project)
	project.undo_redo.add_undo_method(Global, "undo_or_redo", true, -1, -1, project)
	project.undo_redo.commit_action()


func _get_undo_data(project: Project) -> Dictionary:
	var data := {}

	var images := _get_selected_draw_images(project)
	for image in images:
		image.unlock()
		data[image] = image.data

	return data
