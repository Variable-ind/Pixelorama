class_name VectorTextShape
extends VectorBaseShape

var pos: Vector2
var text: String:
	set(value):
		text = value
		lines = value.split("\n", false)
var font: FontFile
var font_size: int
var outline_size: int
var extra_spacing: Vector2
var color: Color
var outline_color: Color
var antialiased: bool

var lines: PackedStringArray  # Made from text split into each of its new lines


func draw(canvas_item: RID) -> void:
	#font.extra_spacing_char = extra_spacing.x
	#font.extra_spacing_bottom = extra_spacing.y
	#font.font_data.antialiased = antialiased
	var line_pos := Vector2(pos.x, pos.y + font.get_height())
	for line in lines:
		font.draw_string(
			canvas_item,
			line_pos,
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			color,
			TextServer.JUSTIFICATION_NONE,
			TextServer.DIRECTION_AUTO,
			TextServer.ORIENTATION_HORIZONTAL
		)
		font.draw_string_outline(
			canvas_item,
			line_pos,
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			outline_size,
			outline_color,
			TextServer.JUSTIFICATION_NONE,
			TextServer.DIRECTION_AUTO,
			TextServer.ORIENTATION_HORIZONTAL
		)
		line_pos.y += font.get_height()


func has_point(point: Vector2i) -> bool:
	# TODO: For adding rotation, the trick will probably be to first rotate the point around this shape's pivot point
	#font.extra_spacing_char = extra_spacing.x
	#font.extra_spacing_bottom = extra_spacing.y
	var line_pos := pos
	for line in lines:
		var string_size = font.get_string_size(
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			TextServer.JUSTIFICATION_NONE,
			TextServer.DIRECTION_AUTO,
			TextServer.ORIENTATION_HORIZONTAL
		)
		if Rect2(line_pos, string_size).has_point(point):
			return true
		line_pos.y += font.get_height()
	return false


func serialize() -> Dictionary:
	return {
		"type": Global.VectorShapeTypes.TEXT,
		"pos": [pos.x, pos.y],
		"text": text,
		"font_data": font.data,
		"f_size": font_size,
		"ol_size": outline_size,
		"ex_sp": extra_spacing,
		"col": color.to_html(true),
		"ol_col": outline_color.to_html(true),
		"aa": antialiased,
	}


func deserialize(dict: Dictionary) -> void:
	pos = Vector2(dict["pos"][0], dict["pos"][1])
	self.text = dict["text"]  # Call the setter too
	font.set_data(dict["font_data"])
	font_size = dict["f_size"]
	outline_size = dict["ol_size"]
	extra_spacing = Vector2(dict["ex_sp"][0], dict["ex_sp"][1])
	color = Color(dict["col"])
	outline_color = Color(dict["ol_col"])
	antialiased = dict["aa"]
