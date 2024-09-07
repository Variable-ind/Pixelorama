extends ConfirmationDialog

const TITLES := {
	"NAME": "Name",
	"DESCRIPTION": "Description",
	"OLD_VERSION": "Old Version",
	"NEW_VERSION": "New Version",
	"UPDATE": "Update"
}
const split_offsets: Array[float] = [150, 340, 85, 0]
var batch_update_multilist: MultiList
var update_settings: Dictionary


func _ready() -> void:
	batch_update_multilist = MultiList.new(
		[TITLES.NAME, TITLES.DESCRIPTION, TITLES.OLD_VERSION, TITLES.NEW_VERSION, TITLES.UPDATE],
	)
	batch_update_multilist.set_offsets(split_offsets)
	batch_update_multilist.name = "UpdateList"
	$VBoxContainer.add_child(batch_update_multilist)
	#batch_update_multilist.top_bar.max_size_x = $VBoxContainer.size.x
	batch_update_multilist.value_changed.connect(setting_changed)


func add_queue(info: Dictionary):
	var update_entry_dict: Dictionary
	var installed_extensions = Global.control.get_node("Extensions").extensions
	for extension: Extensions.Extension in installed_extensions.values():
		if extension.file_name == info["name"]:
			update_entry_dict[TITLES.NAME] = extension.file_name
			update_entry_dict[TITLES.DESCRIPTION] = extension.description
			update_entry_dict[TITLES.OLD_VERSION] = str(extension.version)
			update_entry_dict[TITLES.NEW_VERSION] = str(info["version"])
			update_entry_dict[TITLES.UPDATE] = true
			batch_update_multilist.add_entry(update_entry_dict, extension.file_name)


func setting_changed(row_header, _param, value):
	if typeof(value) == TYPE_BOOL:
		update_settings[row_header] = value


func _on_confirmed() -> void:
	pass # Replace with function body.
