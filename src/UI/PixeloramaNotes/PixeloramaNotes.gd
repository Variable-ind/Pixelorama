extends PanelContainer

const NumberList = """[ol type=1]

[/ol]"""


@onready var output: VBoxContainer = %Output
@onready var code: TextEdit = %Code


func _on_tab_container_tab_changed(tab: int) -> void:
	if tab == 0:
		compile_and_serve(code.text)


func compile_and_serve(text: String):
	for child in output.get_children():
		child.queue_free()
	var sections := text.split("\n", false)
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
		elif line.begins_with("[ ]"):
			pass
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


func _on_code_text_changed() -> void:
	compile_and_serve(code.text)
