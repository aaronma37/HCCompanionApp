extends RichTextLabel

var term_text = ""

func _ready():
	newline()

func push_msg(msg):
	term_text += "    " + msg + "\n"
	set_bbcode(term_text)
