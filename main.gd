extends Node2D

const valid_dirs = ["_classic_era_", "WTF"]
const get_url = ""
var characters = {}
var requires_time_update = {}
var synced = []
var mutex = Mutex.new()
var http_request = HTTPRequest.new()
var term = Term.new()



var save_path = "user://hc_companion_save.dat"
# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(term)
	term.Print("Initializing...")
	OS.set_borderless_window(true)
	get_tree().get_root().set_transparent_background(true)
	http_request.connect("request_completed", self, "_on_request_completed")
	add_child(http_request)
	loadVars()
	
	#Setup watchdog
	var timer = Timer.new()
	timer.set_wait_time(3.0)
	timer.connect("timeout", self, "watchdog")
	add_child(timer)
	timer.start()
	
func watchdog():
	mutex.lock()
	get_node("PanelContainer/VBoxContainer/ScrollContainer2/FilePathMarginContainer/WoWPathText").refresh()
	if detectCorrectDirectory(get_node("/root/Global").globals["wow_path"], false):
		detectCharacters(get_node("/root/Global").globals["wow_path"], "None", "None", "None")
		get_node("PanelContainer/VBoxContainer/ScrollContainer/ItemList").refresh(characters)
		detectVersion(get_node("/root/Global").globals["wow_path"])
		saveVars()
	mutex.unlock()

func saveVars():
	var file = File.new()
	file.open(save_path, File.WRITE)
	file.store_var(get_node("/root/Global").globals)
	file.close()
	
func loadVars():
	mutex.lock()
	var file = File.new()
	if file.file_exists(save_path):
		var err = file.open(save_path, File.READ)
		if err == OK:
			var loaded_vars = file.get_var()
			for k in loaded_vars.keys():
				get_node("/root/Global").globals[k] = loaded_vars[k]
			file.close()
			get_node("PanelContainer/VBoxContainer/ScrollContainer2/FilePathMarginContainer/WoWPathText").refresh()
			if detectCorrectDirectory(get_node("/root/Global").globals["wow_path"], true):
				detectCharacters(get_node("/root/Global").globals["wow_path"], "None", "None", "None")
				get_node("PanelContainer/VBoxContainer/ScrollContainer/ItemList").refresh(characters)
				detectVersion(get_node("/root/Global").globals["wow_path"])
				saveVars()
				updateLocalSavedVariables()
	mutex.unlock()
	term.Print("Initialization complete.")
		
func updateLocalSavedVariables():
	var payload = {}
	for k in characters.keys():
		payload[characters[k]["name"]] = k
	var query = JSON.print(payload)
	var headers = ["Content-Type: application/json"]
	var err = http_request.request(get_url, headers, false, HTTPClient.METHOD_POST, query)
	#var err = http_request.request(get_url + "?name=yazap".http_escape())
	if err != OK:
		term.Print("Error when attempting request from server: " + err)

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	for data in json.result["Responses"]["HC_Character_DB"]:
		for guid_key in data["guid"].keys():
			if guid_key in characters:
				if (characters[guid_key]["name"] != data["name"]):
					term.Print("Error resolving incoming name/guid and current db.", guid_key, data["name"], characters)
					continue
				if int(data["guid"][guid_key]["time_tracked"]) > int(characters[guid_key]["time_tracked"]):
					term.Print("Updating local saved variables for " + data["name"] + "...[color=green]"  + characters[guid_key]["time_tracked"]  + "-->" + data["guid"][guid_key]["time_tracked"] + "[/color]")
					requires_time_update[guid_key] = characters[guid_key]["time_tracked"]
					var file = File.new()
					file.open(characters[guid_key]["SavedVarPath"], File.READ_WRITE)
					var content = file.get_as_text()
					var modified_content = content.replace(characters[guid_key]["time_tracked"], data["guid"][guid_key]["time_tracked"])
					file.store_string(modified_content)
					term.Print("Completed updating local saved variables for " + data["name"])
					file.close()
				synced.push_back(guid_key)
				term.Print("Received SavedVariables for " + data["name"])
	term.Print("Completed http request.")
	
	# If data is not gathered from server for a particular character, attempt to add it again
	for k in characters.keys():
		if !(k in synced):
			get_node("/root/Global").requires_post[k] = true

func detectCorrectDirectory(path, warn):
	var dir = Directory.new()
	if dir.dir_exists(path) and dir.dir_exists(path + "/_classic_era_"):
		if (warn):
			term.Print("[color=green]World of Warcraft directory detected!!![/color]")
		get_node("/root/Global").correct_dir = true
		return true
	else:
		if (warn):
			term.Print("[color=yellow]Currently selected directory is incorrect.  Please set to the root of your World of Warcraft directory.[/color]")
		get_node("/root/Global").correct_dir = false
		return false
	
func detectCharacters(path, current_dir_name, server_name, character_name):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if valid_dirs.has(file_name):
					detectCharacters(dir.get_current_dir() + "/" + file_name, file_name, "", "")
				elif current_dir_name == "WTF":
					if file_name == "Account":
						detectCharacters(dir.get_current_dir() + "/" + file_name, file_name, "", "")
				elif current_dir_name == "Account" and (file_name != "." and file_name != ".."):
					detectCharacters(dir.get_current_dir() + "/" + file_name, "Account_Dir", "", "")
				elif current_dir_name == "Account_Dir" and (file_name != "." and file_name != ".." and file_name != "SavedVariables"):
					detectCharacters(dir.get_current_dir() + "/" + file_name, "Servers", file_name, "")
				elif current_dir_name == "Servers" and (file_name != "." and file_name != ".."):
					detectCharacters(dir.get_current_dir() + "/" + file_name, "Characters", server_name, file_name)
				elif current_dir_name == "Characters" and file_name == "SavedVariables":
					detectCharacters(dir.get_current_dir() + "/" + file_name, "Characters", server_name, character_name)
			elif file_name == "Hardcore.lua":
				readCharacterSavedVars(dir.get_current_dir() + "/" + file_name, server_name, character_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		
func readCharacterSavedVars(path, server_name, character_name):
	var character_data = {
		"name": character_name,
		"server": server_name,
		"guid": "?",
		"tracked_played_percentage": "?",
		"time_tracked": "?",
		"time_played": "?",
		"trade_partners": "?",
		"played_time_gap_warnings": "?",
		"bubble_hearth_incidents": "?",
		"deaths": 0,
		"synced": false,
	}
	var guid = "?"
	var tracked_played_percentage = "?"
	var file = File.new()
	#print(path)
	file.open(path, File.READ)
	var content = file.get_as_text()
	var removed_header = content.split("Hardcore_Character = {")[1]
	#print(content)
	var comma_split = removed_header.split(",")
	for i in comma_split.size():
		var equals_split = comma_split[i].split("=")
		for k in character_data.keys():
			if k in equals_split[0]:
				character_data[k] = equals_split[1].replace(",", "").replace("{","").replace("}","").strip_escapes()
				break
	character_data["modification_date"] = file.get_modified_time(path)
	character_data["SavedVarPath"] = path
	if !(character_data["guid"] in get_node("/root/Global").globals['last_modified'].keys()) or get_node("/root/Global").globals['last_modified'][character_data["guid"]] != character_data["modification_date"]:
		get_node("/root/Global").requires_post[character_data["guid"]] = true

	get_node("/root/Global").globals['last_modified'][character_data["guid"]] = character_data["modification_date"]
	file.close()
	if character_data["guid"] == "?":
		return
	if character_data["guid"] in synced:
		character_data["synced"] = true
	characters[character_data["guid"]] = character_data
	

func detectVersion(path):
	var file = File.new()
	var file_name = get_node("/root/Global").globals['wow_path']  + "/_classic_era_/Interface/AddOns/Hardcore/Hardcore.toc"
	get_node("/root/Global").globals['version_info'] = {}
	var err = file.open(file_name, File.READ)
	if err != OK:
		get_node("/root/Global").globals['version_info']["version"] = "Addon not found."
	else:
		get_node("/root/Global").globals['version_info']["version"] = "Version not found."
	var content = file.get_as_text()
	var split = content.split("##")
	for v in split:
		var version_split = v.split("Version: ")
		if version_split.size() == 2:
			get_node("/root/Global").globals['version_info']["version"] = version_split[1].strip_escapes()
			break
	file.close()

	
	file_name = get_node("/root/Global").globals['wow_path']  + "/_classic_era_/Interface/AddOns/Hardcore/Hardcore.lua"
	file.close()
	err = file.open(file_name, File.READ)
	if err != OK :
		if get_node("/root/Global").correct_dir:
			term.Print("Error inspecting addon authenticity.")
		get_node("/root/Global").globals['version_info']["checksum"] = "none"
		return
	content = file.get_as_text()
	content = content + get_node("/root/Global").SECRET
	get_node("/root/Global").globals['version_info']["checksum"] = content.md5_text()
	file.close()
	get_node("PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/CenterContainer/MarginContainer3/AddonVersionLabel").refresh(content.md5_text())

func console_print(msg):
	get_node("PanelContainer/VBoxContainer/ScrollContainer3").append_to_term(msg)
