extends Window


func _on_visibility_changed() -> void:
	if visible:
		return
	Global.dialog_open(false)


func _on_close_requested() -> void:
	hide()


