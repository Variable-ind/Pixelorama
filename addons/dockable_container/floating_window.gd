class_name FloatingWindow
extends Window

signal data_changed

var window_content: Control
var _is_initialized: bool


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		if not window_content.get_rect().has_point(event.position) and _is_initialized:
			data_changed.emit(name, serialize())


func _init(content: Control, data := {}) -> void:
	window_content = content
	title = window_content.name
	name = window_content.name
	min_size = window_content.get_minimum_size()
	unresizable = false
	wrap_controls = true
	ready.connect(_deserialize.bind(data))
	size = window_content.size
	position = DisplayServer.window_get_size() / 2 - size / 2


func _deserialize(data: Dictionary) -> void:
	window_content.get_parent().remove_child(window_content)
	window_content.visible = true
	window_content.global_position = Vector2.ZERO
	add_child(window_content)
	size_changed.connect(window_size_changed)
	if not data.is_empty():
		if "position" in data:
			set_position(data["position"])
		if "size" in data:
			size = data["size"]
	_is_initialized = true


func serialize() -> Dictionary:
	return {"size": size, "position": position}


func window_size_changed():
	window_content.size = size
	window_content.position = Vector2.ZERO
	if _is_initialized:
		data_changed.emit(name, serialize())


func destroy():
	size_changed.disconnect(window_size_changed)
	queue_free()


func _exit_tree() -> void:
	if _is_initialized:
		data_changed.emit(name, {})
