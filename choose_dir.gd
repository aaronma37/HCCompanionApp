extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var file_dialog = FileDialog.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("pressed", self, "_button_pressed")

	add_child(file_dialog)
	file_dialog.set_size(Vector2(800,400))
	file_dialog.window_title = "Choose WoW Directory"
	file_dialog.access = 2
	file_dialog.mode = 2
	file_dialog.connect("dir_selected", self, "_dir_selected")


func _button_pressed():
	file_dialog.popup()
	
func _dir_selected(dir):
	get_node("/root/Global").globals['wow_path'] = dir
	get_tree().root.get_child(1).detectCorrectDirectory(dir, true)
	get_parent().get_parent().get_node("FilePathMarginContainer/WoWPathText").refresh()
	get_parent().get_parent().get_parent().get_parent().get_parent().saveVars()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
