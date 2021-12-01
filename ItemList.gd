extends ItemList

const update_url = ""
onready var checkmark =  preload("res://checkmark.tscn")

var checkmark_texture = load("res://Images/checkmark.png")
var warning_texture = load("res://Images/warning.png")
var dead_texture = load("res://Images/dead.png")
var warning_for_char = {}
var term = Term.new()
var http_request = HTTPRequest.new()
var names = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(term)
	add_child(http_request)
	http_request.connect("request_completed", self, "_on_request_completed")
	pass
	

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	if result == OK and json.result["Attributes"]["guid"].keys()[0] in names:
		term.Print("Update successful for " + names[json.result["Attributes"]["guid"].keys()[0]])
	else:
		term.Print("Upload error: ", result)
		
func refresh(characters):
	clear()
	self.add_item("server")
	self.add_item("name")
	self.add_item("HC status")
	self.add_item("last modified")
	self.add_item("last updated")
	self.add_item("sync status")


	var t = Timer.new()
	t.set_wait_time(2)
	t.set_one_shot(true)
	self.add_child(t)
	self.fixed_icon_size = Vector2(15,15)

	for guid in characters.keys():
		self.add_item(characters[guid]["server"])
		self.add_item(characters[guid]["name"])
		names[guid] = characters[guid]["name"]
		var result = checkCharacterData(characters[guid])
		self.add_item(result[1], result[0])
		var time = OS.get_datetime_from_unix_time(characters[guid]["modification_date"])
		self.add_item(str(time["month"]) + "/" + str(time["day"]) + "/" +  str(time["year"]) + ", " +  str(time["hour"]) + ":" + str(time["minute"]))
		time = OS.get_datetime()
		self.add_item(str(time["month"]) + "/" + str(time["day"]) + "/" +  str(time["year"]) + ", " +  str(time["hour"]) + ":" + str(time["minute"]))
		if characters[guid]["synced"]:
			self.add_item("Completed")
		else:
			self.add_item("")
		if guid in get_node("/root/Global").requires_post and get_node("/root/Global").requires_post[guid]:
			get_node("/root/Global").requires_post[guid] = false
			var query = JSON.print(characters[guid])
			var headers = ["Content-Type: application/json"]
			http_request.request(update_url, headers, false, HTTPClient.METHOD_POST, query)
			t.start()
			yield(t, "timeout")
			term.Print("Uploading data for " + characters[guid]["name"] + "...")
	t.queue_free()

func checkCharacterData(character_data):
	if int(character_data["deaths"]) > 0:
		if !(character_data["guid"] in warning_for_char):
			term.Print("[color=red]Character " + character_data["name"] + " has a recorded death.[/color]")
		warning_for_char[character_data["guid"]] = true
		return [dead_texture, ""]
	elif float(character_data["tracked_played_percentage"]) < 90:
		if !(character_data["guid"] in warning_for_char):
			term.Print("[color=yellow]Character " + character_data["name"] + " has under 90% played time.[/color]")
		warning_for_char[character_data["guid"]] = true
		return [warning_texture, ""]
	return [checkmark_texture, ""]
