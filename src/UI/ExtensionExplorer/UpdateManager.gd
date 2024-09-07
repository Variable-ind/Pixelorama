extends ConfirmationDialog

const TITLES := {
	"NAME": "Name",
	"DESCRIPTION": "Description",
	"OLD_VERSION": "Old Version",
	"NEW_VERSION": "New Version",
	"UPDATE": "Update"
}
const split_offsets: Array[float] = [120, 300, 80, 80]
var batch_update_multilist: Table
var update_settings: Dictionary


func _ready() -> void:
	batch_update_multilist = Table.new(
		[TITLES.NAME, TITLES.DESCRIPTION, TITLES.OLD_VERSION, TITLES.NEW_VERSION, TITLES.UPDATE],
	)
	batch_update_multilist.set_split_sizes(split_offsets)
	batch_update_multilist.name = "UpdateList"
	$VBoxContainer.add_child(batch_update_multilist)
	batch_update_multilist.top_bar.max_size_x = $VBoxContainer.size.x
	batch_update_multilist.value_changed.connect(setting_changed)


func add_queue(info: Dictionary, entry):
	var update_entry_dict: Dictionary
	var installed_extensions = Global.control.get_node("Extensions").extensions
	for extension: Extensions.Extension in installed_extensions.values():
		if extension.file_name == info["name"]:
			update_entry_dict[TITLES.NAME] = extension.file_name
			update_entry_dict[TITLES.DESCRIPTION] = extension.description
			update_entry_dict[TITLES.OLD_VERSION] = str(extension.version)
			update_entry_dict[TITLES.NEW_VERSION] = str(info["version"])
			update_entry_dict[TITLES.UPDATE] = true
			batch_update_multilist.add_row(update_entry_dict)


func setting_changed(uid, param, value):
	if typeof(value) == TYPE_BOOL:
		pass
