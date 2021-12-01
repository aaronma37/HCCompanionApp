extends ScrollContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var lock_bottom = true
const scroll_speed = 4
var last_pos = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func append_to_term(msg):
	get_node("MarginContainer/TermText").push_msg(msg)
	if lock_bottom:
		scroll_vertical = min(scroll_vertical + scroll_speed, get_v_scrollbar().max_value)

		
func _process(delta):
	if scroll_vertical < last_pos:
		lock_bottom = false
	last_pos = scroll_vertical
	
	if lock_bottom == false and  scroll_vertical > get_v_scrollbar().max_value - get_v_scrollbar().page - 20:
		lock_bottom = true

	if lock_bottom:
		scroll_vertical = min(scroll_vertical + scroll_speed, get_v_scrollbar().max_value)
