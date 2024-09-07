class_name Table
extends VBoxContainer

signal value_changed

var top_bar = MultiSplitContainer.new()
var column_names: Array[StringName]
var current_uids: Array[int]
var _sections :Dictionary
var rows_container := GridContainer.new()


func _init(names: Array[StringName]) -> void:
	column_names = names
	add_child(top_bar)
	rows_container.add_theme_constant_override("h_separation", 0)
	rows_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for i in names.size():
		var list_name = names[i]
		var section = Section.new(list_name, Color.BLUE, self)
		var spacer = Control.new()
		rows_container.add_child(spacer)
		_sections[list_name] = section
		top_bar.add_child(section.title_label)
		if i == names.size() - 1:
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			section.title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			## Also add a way to reset accidentally changed custom_minimum_size
			section.title_label.resized.connect(
				func ():
					spacer.custom_minimum_size.x = 0
					section.title_label.custom_minimum_size.x = 0
			)
		else:
			section.title_label.resized.connect(
				func (): spacer.custom_minimum_size.x = section.title_label.size.x
			)
	rows_container.columns = _sections.keys().size()
	add_child(rows_container)


func set_split_sizes(offsets: Array[float]) -> void:
	if offsets.size() >= top_bar.get_child_count() - 1:
		for i in top_bar.get_child_count() - 1:
			top_bar.get_child(i).custom_minimum_size.x = offsets[i]


func add_row(dictionary: Dictionary) -> int:
	var uid := _create_new_uid()
	for param in column_names:
		var section: Section = _sections[param]
		var ui_nodes = _get_parameter_ui_nodes(uid, dictionary)
		if param in dictionary.keys():
			var item = ui_nodes[param]
			section.new_block(item, true)
	return uid


func remove_row(uid: int):
	for section in _sections.values():
		section.remove_block(uid)


func clear():
	for section: Section in _sections.values():
		section.clear()


func highlight_entry(idx: int):
	for section: Section in _sections.values():
		section.enable_highlight(idx)


func get_index_from_uid(uid: int) -> int:
	return _sections[0].get_index_from_uid(uid)


func _get_parameter_ui_nodes(uid: int, dict: Dictionary) -> Dictionary:
	var output_dict: Dictionary
	for param in dict.keys():
		var value = dict[param]
		var item: Control
		var emitter_lambdha := func (): value_changed.emit(uid, param, value)
		match typeof(value):
			TYPE_STRING_NAME:
				item = Label.new()
				item.text = value
				item.clip_text = true
				item.mouse_filter = Control.MOUSE_FILTER_PASS
			TYPE_STRING:
				item = RichTextLabel.new()
				item.fit_content = true
				item.text = value
				item.mouse_filter = Control.MOUSE_FILTER_PASS
			TYPE_BOOL:
				var box = CheckBox.new()
				box.button_pressed = value
				box.toggled.connect(emitter_lambdha)
				item = PanelContainer.new()
				item.add_child(box)
				item.custom_minimum_size = box.size
				box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				item.mouse_filter = Control.MOUSE_FILTER_PASS
			TYPE_COLOR:
				item = ColorPickerButton.new()
				item.color = value
				item.color_changed.connect(emitter_lambdha)
			TYPE_FLOAT:
				item = SpinBox.new()
				item.value = value
				item.value_changed.connect(emitter_lambdha)
			TYPE_INT:
				item = SpinBox.new()
				item.step = 1
				item.value = value
				item.value_changed.connect(emitter_lambdha)
			_:
				item = Control.new()
		output_dict[param] = item
	return output_dict


func _create_new_uid() -> int:
	for i in current_uids.size() + 1:
		if not i in current_uids:
			current_uids.append(i)
			return i
	var uid = current_uids.size() + 1
	current_uids.append(uid)
	return uid
