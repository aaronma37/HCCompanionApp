extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var globals = {
	"wow_path": "None",
	"characters": {},
	"version_info": {},
	"last_modified": {},
	"requires_post": {}
	}

var correct_dir = false
var requires_post = {}

const HASHES = {"0.5.0": "", "0.6.0": "", "0.7.0": ""}
const SECRET = ""
const latest = "0.7.0"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
