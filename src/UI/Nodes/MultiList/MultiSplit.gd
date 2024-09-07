class_name MultiSplit
extends GridContainer

const DRAG_THRESHOLD := 5

var drag_split_index: int = -1
var drag_started := false
var splits: Array[float]
var max_size_x: float:
	set(value):
		max_size_x = value
		var ch = get_children()
		ch.reverse()
		var i = 0
		while size.x > value:
			if i < ch.size():
				ch[i].custom_minimum_size.x -= 1
				if ch[i].custom_minimum_size.x <= 10:
					i += 1
			else: break


func _init() -> void:
	sort_children.connect(set_up_information)
	add_theme_constant_override("h_separation", 0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if get_rect().has_point(event.position):
			if not drag_started:
				drag_split_index = -1
				for i in splits.size():
					var split := splits[i]
					if absf(event.position.x - split) <= DRAG_THRESHOLD:
						drag_split_index = i
						mouse_default_cursor_shape = CURSOR_HSPLIT
						break
					else:
						mouse_default_cursor_shape = CURSOR_ARROW
		if drag_started:
			var offset = event.position.x - splits[drag_split_index]
			get_child(drag_split_index).custom_minimum_size.x += offset
			if max_size_x > 0:
				while size.x > max_size_x:
					get_child(drag_split_index).custom_minimum_size.x -= 1


## we need some things to trigger even after mouse exits boundary
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and drag_split_index != -1:
			drag_started = true
		else:
			drag_started = false


func set_up_information():
	columns = get_child_count()
	splits.clear()
	for child_idx: int in get_child_count():
		var separation = get_theme_constant("h_separation")
		var child = get_child(child_idx)
		var split_point = child.position.x + child.size.x + (separation / 2.0)
		splits.append(split_point)
