extends ConfirmationDialog

onready var from_proj = $HBoxContainer2/From/From
var curr_proj_idx :int
var target :Project


func _on_MergeProject_about_to_show():
	target = Global.current_project
	curr_proj_idx = Global.current_project_index
	for i in from_proj.get_item_count():
		from_proj.remove_item(0)
	$HBoxContainer2/To/Target.text = target.name

	for project in Global.projects.size():
		from_proj.add_item(Global.projects[project].name)
		if project == curr_proj_idx:
			from_proj.set_item_disabled(from_proj.get_item_count()-1,true)


func _on_MergeProject_confirmed():
	var from :Project = Global.projects[from_proj.selected]
	if from == Global.current_project:
		return
	var project_width :int = max(from.size.x, Global.current_project.size.x)
	var project_height :int = max(from.size.y, Global.current_project.size.y)
	DrawingAlgos.resize_canvas(project_width, project_height, 0, 0)
	
	for layer in from.layers.size():
		Global.animation_timeline.add_layer(true)
		target.layers[target.layers.size() - 1].name = from.layers[layer].name
		for frame in from.frames.size():
			if frame > target.frames.size() - 1:
				OpenSave.open_image_as_new_frame(from.frames[frame].cels[layer].image, target.layers.size() - 1)
			else:
				OpenSave.open_image_at_frame(from.frames[frame].cels[layer].image, target.layers.size() - 1, frame)
	
