extends Node

var width = 1920
var height = 1080
var fullscreen = true
var blood = true
var high_score = 100000
var config = null
var config_path = "config.cfg"


func _init():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	load_config()


func load_config():
	config = ConfigFile.new()
	
	if config.load(config_path) == OK:
		width = config.get_value("config", "width")
		height = config.get_value("config", "height")
		fullscreen = config.get_value("config", "fullscreen")
		blood = config.get_value("config", "blood")
		high_score = config.get_value("score", "high_score")
	else:
		config.set_value("config", "width", width)
		config.set_value("config", "height", height)
		config.set_value("config", "fullscreen", fullscreen)
		config.set_value("config", "blood", blood)
		config.set_value("score", "high_score", high_score)
		config.save(config_path)
	
	if not fullscreen:
		OS.window_fullscreen = false
		OS.set_window_size(Vector2(width, height))


func save_high_score(new_score):
	high_score = new_score
	config.set_value("score", "high_score", new_score)
	config.save(config_path)


func _process(delta):
	if Input.is_action_pressed("quit"):
		get_tree().quit()
