extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var mouse_in_position = false
var dragging = false
var initial_pos = null
var initial_window_pos = null

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", self, "entered")
	connect("mouse_exited", self, "exited")
	pass # Replace with function body.

func entered():
	mouse_in_position = true
	
func exited():
	if dragging == false:
		mouse_in_position = false

func _input(event):
	if mouse_in_position:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				if event.pressed and dragging == false:
					dragging = true
					initial_pos = get_local_mouse_position()
					print("initial pose")
					initial_window_pos = OS.window_position
				else:
					dragging = false
					
	if event is InputEventMouseMotion:
		if dragging:
			OS.window_position +=  get_local_mouse_position() - initial_pos
