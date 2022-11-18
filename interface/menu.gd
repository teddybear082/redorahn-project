extends Spatial

var broken_material = preload("res://natural/Egg_broken.material")


func _ready():
	$AnimationPlayer.play("jingle")


func _process(delta):
	$Cave/Lava.get_surface_material(0).uv1_offset.x += 0.005


func _input(event):
	if $AnimationPlayer.is_playing():
		return
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		$AnimationPlayer.play("start")
		$StartSound.play()
		$Menu/PressStart.visible = false
		$PressTimer.stop()
		$Music.stop()
		$Egg.set_surface_material(0, broken_material)


func start_game():
	get_tree().change_scene("res://game/game.tscn")


func switch_press_text():
	$Menu/PressStart.visible = not $Menu/PressStart.visible
