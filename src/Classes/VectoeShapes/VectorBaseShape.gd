class_name VectorBaseShape
extends RefCounted

# Draw the shape on this CanvasItem RID using the VisualServer
func draw(_canvas_item: RID) -> void:
	return


# Is point inside this shape? Useful for selecting the shape with a mouse click
func has_point(_point: Vector2i) -> bool:
	return false
