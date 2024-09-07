class_name Block
extends RefCounted

signal highlighted

## the highlight color
var highlight_color: Color
var content: Control
var uid: int

var color: Color:
	set(value):
		_highlight_panel.color = value

var _highlight_panel := ColorRect.new()


func _init(
	item: Control, b_uid: int, parent: GridContainer, highlight_col: Color, is_interactable := true
) -> void:
	uid = b_uid
	color = Color.TRANSPARENT
	highlight_color = highlight_col
	content = item
	_highlight_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(_highlight_panel)
	parent.add_child(item)
	_highlight_panel.size = item.size
	_highlight_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	if is_interactable:
		content.gui_input.connect(_highlight_on)


func _highlight_on(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			highlighted.emit(uid)


func highlight(enabled: bool):
	if enabled:
		var light = highlight_color
		light.a = 0.3
		color = light
	else:
		color = Color.TRANSPARENT
