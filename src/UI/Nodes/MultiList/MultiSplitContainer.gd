class_name MultiSplitContainer
extends GridContainer

const DRAG_THRESHOLD := 5
const PAUSE_DRAG_THRESHOLD := 5

var drag_split_index: int = -1
var drag_started := false:
	set(value):
		drag_started = value
		_old_splits = splits.duplicate()
		_old_min_sizes.clear()
		for child in get_children():
			_old_min_sizes.append(child.custom_minimum_size.x)
var splits: Array[float]
var max_size_x: float:
	set(value):
		_pause_offset = value
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
var _old_splits: Array[float]
var _old_min_sizes: Array[float]
var _pause_offset: float = INF

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
			## Push/Pull the column to correct position
			## NOTE: simply using event.position.x - splits[drag_split_index] often resulted
			## in wrong sign
			var offset = event.position.x - _old_splits[drag_split_index]
			if offset > _pause_offset:
				return
			else:
				_pause_offset = max_size_x
			var new_min_size = _old_min_sizes[drag_split_index] + offset
			var split_child := get_child(drag_split_index)
			split_child.custom_minimum_size.x = maxf(0, new_min_size)

			## Push/Pull the next column to correct position
			var adjust_split = drag_split_index + 1
			var new_adjust_split_min_size = _old_min_sizes[adjust_split] - offset
			var child_to_move = get_child(adjust_split)
			if adjust_split < _old_splits.size() - 1 and new_adjust_split_min_size > 0:
				if not (offset < 0 and adjust_split < _old_splits.size() - 1):
					child_to_move.custom_minimum_size.x = maxf(0, new_adjust_split_min_size)

			## Handle container size being changed (lock it if required)
			if max_size_x > 0 and size.x > max_size_x:
				var try := 0
				if offset < 0 and adjust_split < _old_splits.size() - 1:
					return
				## NOTE: using While is the only way this works. I have already tried:
				## split_child.custom_minimum_size.x -= offset
				## but it doesn'tseem to work
				while size.x > max_size_x and try <= abs(offset):
					if size.x - max_size_x >= PAUSE_DRAG_THRESHOLD:
						_pause_offset = offset
					split_child.custom_minimum_size.x -= 1
					size.x = max_size_x
					try += 1


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
	for child_idx: int in get_child_count() - 1:
		var separation = get_theme_constant("h_separation")
		var child = get_child(child_idx)
		var split_point = child.position.x + child.size.x + (separation / 2.0)
		splits.append(split_point)
