class_name ProjectNotes
extends PanelContainer

enum List { BULLET, NUMBER, LOWER_LATIN, UPPER_LATIN, LOWER_ROMAN, UPPER_ROMAN }
const OListBlueprint = "[ol type=%s]\n\t\n[/ol]"
const UListBlueprint = "[ul]\n\t\n[/ul]"
const DemoText = """### Project Notes
For helpful tips, click the Help button in [color=green]Code[/color] tab.
Enjoy.

[hr]"""

@onready var add_list: MenuButton = %AddList
@onready var output: VBoxContainer = %Output
@onready var code: TextEdit = %CodeEdit


func _on_tab_container_tab_changed(tab: int) -> void:
	if tab == 0:
		compile_and_serve(code.text)


func _on_code_edit_text_changed() -> void:
	if code.text != Global.current_project.user_data:
		Global.current_project.user_data = code.text


func update_text(new_text: String) -> void:
	code.text = new_text
	compile_and_serve(code.text)


func _ready() -> void:
	Global.project_switched.connect(update_text)
	var list_popup := add_list.get_popup()
	list_popup.add_item("*...", List.BULLET)
	list_popup.add_item("1, 2, 3...", List.NUMBER)
	list_popup.add_item("a, b, c...", List.LOWER_LATIN)
	list_popup.add_item("A, B, C...", List.UPPER_LATIN)
	list_popup.add_item("i, ii, iii...", List.LOWER_ROMAN)
	list_popup.add_item("I, II, III...", List.UPPER_ROMAN)
	list_popup.id_pressed.connect(_on_add_list)
	compile_and_serve("")


# Lists
func _on_add_list(id: List) -> void:
	var list_text = ""
	match id:
		List.BULLET:
			list_text = UListBlueprint
		List.NUMBER:
			list_text = OListBlueprint % "1"
		List.LOWER_LATIN:
			list_text = OListBlueprint % "a"
		List.UPPER_LATIN:
			list_text = OListBlueprint % "A"
		List.LOWER_ROMAN:
			list_text = OListBlueprint % "i"
		List.UPPER_ROMAN:
			list_text = OListBlueprint % "I"
	add_multiline_operator(list_text)


# Alignment
func _on_a_left_pressed() -> void:
	add_multiline_operator("[left]\n\n[/left]")


func _on_a_center_pressed() -> void:
	add_multiline_operator("[center]\n\n[/center]")


func _on_a_right_pressed() -> void:
	add_multiline_operator("[right]\n\n[/right]")


func _on_a_fill_pressed() -> void:
	add_multiline_operator("[fill]\n\n[/fill]")


func add_multiline_operator(operator: String):
	code.grab_focus()
	for i in code.get_caret_count():
		var old_text := code.get_selected_text(i)
		code.insert_text_at_caret(operator, i)
		code.set_caret_line(code.get_caret_line(i) - 1, true, i)
		if not old_text.is_empty():
			code.insert_text_at_caret(old_text, i)


func compile_and_serve(text: String):
	if text == "":
		text = DemoText
		code.text = DemoText
	for child in output.get_children():
		child.queue_free()
	var sections := text.split("\n", true)
	var last_rich_text: RichTextLabel = null
	for line: String in sections:
		line = line.strip_edges()
		if line.begins_with("#"):
			var header := Label.new()
			header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if line.begins_with("# "):
				header.text = line.trim_prefix("# ")
				header.theme_type_variation = &"HeaderLarge"
			if line.begins_with("## "):
				header.text = line.trim_prefix("## ")
				header.theme_type_variation = &"HeaderMedium"
			if line.begins_with("### "):
				header.text = line.trim_prefix("### ")
				header.theme_type_variation = &"HeaderSmall"
			output.add_child(header)
		else:
			if last_rich_text:
				last_rich_text.text += "\n" + line
			else:
				last_rich_text = RichTextLabel.new()
				last_rich_text.text = line
				last_rich_text.fit_content = true
				last_rich_text.bbcode_enabled = true
				output.add_child(last_rich_text)
			continue
		last_rich_text = null


func _on_button_pressed() -> void:
	OS.shell_open(
		"https://docs.godotengine.org/en/latest/tutorials/ui/bbcode_in_richtextlabel.html#reference"
	)
