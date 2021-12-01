extends Node

class_name Term 

func _ready():
	pass # Replace with function body.

func Print(msg):
	get_tree().root.get_child(1).console_print(msg)
