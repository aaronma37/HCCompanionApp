extends RichTextLabel




func _ready():
	refresh()
	connect("meta_clicked", self, "_meta_clicked")
	
func refresh():
	var bbcode = "WoW directory path: [color=gray]" + get_node("/root/Global").globals['wow_path'] + "[/color]"
	set_bbcode(bbcode)
	
func _meta_clicked( meta ):
	OS.shell_open("https://classichc.net")

