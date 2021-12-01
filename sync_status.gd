extends RichTextLabel

func _ready():
	refresh("-")

func refresh(checksum):
	var bbcode = "Hardcore addon version: "
	if get_node("/root/Global").globals['version_info'].has("version"):
		bbcode += " [color=white][b]" + get_node("/root/Global").globals['version_info']["version"] + "[/b][/color]"
		if !(get_node("/root/Global").globals['version_info']["version"] in get_node("/root/Global").HASHES.keys()):
			bbcode += " [color=yellow] (invalid version) [/color]"
		elif get_node("/root/Global").globals['version_info']["version"] != get_node("/root/Global").latest:
			bbcode += " [color=yellow] (out of date) [/color]"
		if get_node("/root/Global").HASHES[get_node("/root/Global").globals['version_info']["version"]]:
			if checksum == get_node("/root/Global").HASHES[get_node("/root/Global").globals['version_info']["version"]]:
				bbcode += " [color=green]" + "(Authentic)" + "[/color]"
			else:
				bbcode += " [color=red]" + "(modified)" + "[/color]"
		bbcode = bbcode.strip_escapes()
	set_bbcode(bbcode)
