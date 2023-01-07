extends PanelContainer

enum States { ALLOWED, UNBIASED, FORBIDDEN }
var allowed_positions = [
	Vector2.ZERO,
	Vector2(-1, -1),
	Vector2(0, -1),
	Vector2(1, -1),
	Vector2(-1, 0),
	Vector2(1, 0),
	Vector2(-1, 1),
	Vector2(0, 1),
	Vector2(1, 1)
]
var unbiased_positions = []

signal changed

var tl_state = States.ALLOWED
var tc_state = States.ALLOWED
var tr_state = States.ALLOWED
var cl_state = States.ALLOWED
var cr_state = States.ALLOWED
var bl_state = States.ALLOWED
var bc_state = States.ALLOWED
var br_state = States.ALLOWED

var forbidden_tex = preload("res://assets/graphics/misc/icon_pixel_forbidden.png")
var unbiased_tex = preload("res://assets/graphics/misc/icon_pixel_unbiased.png")
var allowed_tex = preload("res://assets/graphics/misc/icon_pixel_allowed.png")
var texture_array = [allowed_tex, unbiased_tex, forbidden_tex]


func is_satisfied(image :Image, pixel :Vector2):
	image.lock()
	var col = image.get_pixelv(pixel)
	var test_array = allowed_positions.duplicate()
	if col.a == 0:
		return false
	for xx in range(-1, 2):
		var x = (pixel.x + xx)
		if xx < image.get_size().x:
			for yy in range(-1, 2):
				var y = (pixel.y + yy)
				if y < image.get_size().y:
					if image.get_pixel(x, y) == col: # This gives nearby pixels
						# If it's in unbiased then move on...
						if Vector2(xx, yy) in unbiased_positions:
							continue
						# If even one of the nearby pixels doesn't satisfy condition
						if not Vector2(xx, yy) in allowed_positions:
							return false
						else:
							test_array.erase(Vector2(xx, yy))
	# if all conditions satisfy then the loop above test_array will be empty
	image.unlock()
	if test_array == []:
		return true
	return false


func _update_positions(state :int, point):
	match state:
		States.ALLOWED:
			allowed_positions.append(point)
			unbiased_positions.erase(point)
		States.UNBIASED:
			allowed_positions.erase(point)
			unbiased_positions.append(point)
		States.FORBIDDEN:
			unbiased_positions.erase(point)
			allowed_positions.erase(point)
	emit_signal("changed")


func _on_TL_pressed():
	tl_state += 1
	if tl_state > 2:
		tl_state = 0
	_update_positions(tl_state, Vector2(-1, -1))
	$GridContainer/TL/TextureRect.texture = texture_array[tl_state]


func _on_TC_pressed():
	tc_state += 1
	if tc_state > 2:
		tc_state = 0
	_update_positions(tc_state, Vector2(0, -1))
	$GridContainer/TC/TextureRect.texture = texture_array[tc_state]


func _on_TR_pressed():
	tr_state += 1
	if tr_state > 2:
		tr_state = 0
	_update_positions(tr_state, Vector2(1, -1))
	$GridContainer/TR/TextureRect.texture = texture_array[tr_state]


func _on_CL_pressed():
	cl_state += 1
	if cl_state > 2:
		cl_state = 0
	_update_positions(cl_state, Vector2(-1, 0))
	$GridContainer/CL/TextureRect.texture = texture_array[cl_state]


func _on_CR_pressed():
	cr_state += 1
	if cr_state > 2:
		cr_state = 0
	_update_positions(cr_state, Vector2(1, 0))
	$GridContainer/CR/TextureRect.texture = texture_array[cr_state]


func _on_BL_pressed():
	bl_state += 1
	if bl_state > 2:
		bl_state = 0
	_update_positions(bl_state, Vector2(-1, 1))
	$GridContainer/BL/TextureRect.texture = texture_array[bl_state]


func _on_BC_pressed():
	bc_state += 1
	if bc_state > 2:
		bc_state = 0
	_update_positions(bc_state, Vector2(0, 1))
	$GridContainer/BC/TextureRect.texture = texture_array[bc_state]


func _on_BR_pressed():
	br_state += 1
	if br_state > 2:
		br_state = 0
	_update_positions(br_state, Vector2(1, 1))
	$GridContainer/BR/TextureRect.texture = texture_array[br_state]


func _on_Middle_pressed():
	get_parent().remove_child(self)
	queue_free()
	emit_signal("changed")
