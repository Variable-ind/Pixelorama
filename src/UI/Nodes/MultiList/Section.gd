class_name Section
extends RefCounted


var title_label := Label.new()
var _blocks: Array[Block]
var entry_highlight: Color
var multilist: MultiList


func _init(title: StringName, highlight: Color, list: MultiList) -> void:
	title_label.text = title
	var a := ColorRect.new()
	title_label.add_child(a)
	a.set_anchors_preset(Control.PRESET_FULL_RECT)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.theme_type_variation = &"HeaderSmall"
	entry_highlight = highlight
	multilist = list


func new_block(item: Control, is_interactable := true) -> Block:
	var uid = multilist.current_uids[-1]
	var block := Block.new(item, uid, multilist.entries_container, entry_highlight, is_interactable)
	block.highlighted.connect(multilist.highlight_entry)
	_blocks.append(block)
	return block


func remove_block(uid: int):
	for block: Block in _blocks:
		if block.uid == uid:
			_blocks.erase(block)
			block.content.queue_free()


func clear():
	for block: Block in _blocks:
		_blocks.erase(block)
		block.content.queue_free()


func clear_highlight():
	for block: Block in _blocks:
		block.highlight(false)


func enable_highlight(uid: int):
	for block: Block in _blocks:
		if block.uid == uid:
			block.highlight(true)
		else:
			block.highlight(false)
