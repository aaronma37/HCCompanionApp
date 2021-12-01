extends RichTextLabel

const bbcode = "Website: [url=https://classichc.net/][color=blue]classichc.net[/color][/url]"

func _ready():
	set_bbcode(bbcode)
	connect("meta_clicked", self, "_meta_clicked")

func _meta_clicked( meta ):
	OS.shell_open("https://classichc.net")

