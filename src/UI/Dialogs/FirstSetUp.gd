extends AcceptDialog

var next_button: Button
@onready var title_name: Label = $VBoxContainer/Title
@onready var setups: VBoxContainer = %Setups

@onready var shrink_slider: ValueSlider = %ShrinkSlider
@onready var font_size_slider: ValueSlider = %FontSizeSlider


func _ready() -> void:
	hide()
	ok_button_text = "Cancel"
	next_button = add_button("Next", true, "next_setup")
	title_name.text = setups.get_child(0).name

	# initial preferences
	shrink_slider.value = Global.shrink
	font_size_slider.value = Global.font_size


func _on_visibility_changed() -> void:
	if visible:
		return
	Global.dialog_open(false)


func _on_close_requested() -> void:
	hide()


func _on_custom_action(action: StringName) -> void:
	if action == "next_setup":
		var next_visible = false
		for child in setups.get_children():
			if next_visible:
				child.visible = true
				title_name.text = child.name
				var ratio = float(child.get_index()) / float(setups.get_child_count() - 1)
				if ratio == 1:
					remove_button(next_button)
					get_ok_button().text = "Finish"
				$VBoxContainer/ProgressBar.value = int(ratio * 100)
				return
			if child.visible:
				child.visible = false
				next_visible = true


# Shrink and Font
func _on_font_size_apply_pressed() -> void:
	Global.font_size = font_size_slider.value
	Global.config_cache.set_value("preferences", "shrink", Global.font_size)


func _on_shrink_slider_value_changed(value: float) -> void:
	Global.shrink = value


func _on_shrink_apply_button_pressed() -> void:
	var root := get_tree().root
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.min_size = Vector2(1024, 576)
	root.content_scale_factor = Global.shrink
	Global.control.set_custom_cursor()
	hide()
	popup_centered(Vector2(600, 400))
	Global.dialog_open(true)
	await get_tree().process_frame
	Global.camera.fit_to_frame(Global.current_project.size)
	Global.config_cache.set_value("preferences", "shrink", Global.shrink)
