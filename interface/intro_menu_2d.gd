extends Node

var game_scene = preload("res://game/game.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func start_game():
	get_tree().change_scene("res://game/game.tscn")


func switch_press_text():
	$Menu/PressStart.visible = not $Menu/PressStart.visible
