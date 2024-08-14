class_name VectorObject
extends Node3D

signal property_changed

enum Type {
	STROKE
}
enum Gizmos { NONE, X_POS, Y_POS, Z_ROT, X_SCALE, Y_SCALE }

var cel
var id := -1
var type := Type.STROKE:
	set = _set_type
var selected := false
var hovered := false
var box_shape: Rect2i
var applying_gizmos: int = Gizmos.NONE

@onready var gizmos_3d: Node2D = Global.canvas.gizmos_3d


func _ready() -> void:
	pass


func find_cel() -> bool:
	var project := Global.current_project
	return cel == project.frames[project.current_frame].cels[project.current_layer]


func serialize() -> Dictionary:
	var dict := {
		"id": id, "type": type, "transform": transform, "visible": visible
	}
	match type:
		Type.STROKE:
			pass  ## TODO: Add stroke properties
	return dict


func deserialize(dict: Dictionary) -> void:
	id = dict["id"]
	type = dict["type"]
	transform = dict["transform"]
	visible = dict["visible"]
	match type:
		Type.STROKE:
			pass  ## TODO: Add stroke properties
	change_property()


func _set_type(value: Type) -> void:
	if type == value:  # No reason to set the same type twice
		return
	type = value
	match type:
		Type.STROKE:
			pass  ## TODO: Add stroke properties
			#node3d_type = MeshInstance3D.new()
			#node3d_type.mesh = BoxMesh.new()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		deselect()
		gizmos_3d.remove_always_visible(self)


func select() -> void:
	selected = true
	gizmos_3d.get_points(camera, self)


func deselect() -> void:
	selected = false
	gizmos_3d.clear_points(self)


func hover() -> void:
	if hovered:
		return
	hovered = true
	if selected:
		return
	gizmos_3d.get_points(camera, self)


func unhover() -> void:
	if not hovered:
		return
	hovered = false
	if selected:
		return
	gizmos_3d.clear_points(self)


func change_transform(a: Vector3, b: Vector3) -> void:
	var diff := a - b
	match applying_gizmos:
		Gizmos.X_POS:
			move_axis(diff, transform.basis.x)
		Gizmos.Y_POS:
			move_axis(diff, transform.basis.y)
		Gizmos.Z_ROT:
			change_rotation(a, b, transform.basis.z)
		Gizmos.X_SCALE:
			change_scale(diff, transform.basis.x, Vector3.RIGHT)
		Gizmos.Y_SCALE:
			change_scale(diff, transform.basis.y, Vector3.UP)
		_:
			move(diff)


func move(pos: Vector3) -> void:
	position += pos
	change_property()


## Move the object in the direction it is facing, and restrict mouse movement in that axis
func move_axis(diff: Vector3, axis: Vector3) -> void:
	var axis_v2 := Vector2(axis.x, axis.y).normalized()
	if axis_v2 == Vector2.ZERO:
		axis_v2 = Vector2(axis.y, axis.z).normalized()
	var diff_v2 := Vector2(diff.x, diff.y).normalized()
	position += axis * axis_v2.dot(diff_v2) * diff.length()
	change_property()


func change_rotation(a: Vector3, b: Vector3, axis: Vector3) -> void:
	var a_local := a - position
	var a_local_v2 := Vector2(a_local.x, a_local.y)
	var b_local := b - position
	var b_local_v2 := Vector2(b_local.x, b_local.y)
	var angle := b_local_v2.angle_to(a_local_v2)
	# Rotate the object around a basis axis, instead of a fixed axis, such as
	# Vector3.RIGHT, Vector3.UP or Vector3.BACK
	rotate(axis.normalized(), angle)
	rotation.x = wrapf(rotation.x, -PI, PI)
	rotation.y = wrapf(rotation.y, -PI, PI)
	rotation.z = wrapf(rotation.z, -PI, PI)
	change_property()


## Scale the object in the direction it is facing, and restrict mouse movement in that axis
func change_scale(diff: Vector3, axis: Vector3, dir: Vector3) -> void:
	var axis_v2 := Vector2(axis.x, axis.y).normalized()
	if axis_v2 == Vector2.ZERO:
		axis_v2 = Vector2(axis.y, axis.z).normalized()
	var diff_v2 := Vector2(diff.x, diff.y).normalized()
	scale += dir * axis_v2.dot(diff_v2) * diff.length()
	change_property()


func change_property() -> void:
	if selected:
		select()
	else:
		# Check is needed in case this runs before _ready(), and thus onready variables
		if is_instance_valid(gizmos_3d):
			gizmos_3d.queue_redraw()
	property_changed.emit()
