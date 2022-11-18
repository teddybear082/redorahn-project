extends Control

var pause = false
var score_screen = false
var flash_high_score = false

onready var health_container = $HUD/HealthContainer
onready var health_bar = $HUD/HealthContainer/HealthBar
onready var score_counter = $HUD/ScoreCounter

onready var score_screen_score = $ScoreScreen/Container/ScoreCounter
onready var score_screen_kills = $ScoreScreen/Container/KillCounter
onready var score_screen_high = $ScoreScreen/Container/HighScoreCounter
onready var score_screen_new = $ScoreScreen/Container/NewHighScoreText
onready var score_screen_press_text = $ScoreScreen/KeyText

onready var pause_label = $PauseLabel
onready var screen_flash = $ScreenFlash
onready var bar_size = health_bar.margin_right


func _ready():
	#screen_flash.flash(Color(0.0, 0.0, 0.0, 1.0), 2.0)
	score_screen_high.text = "HIGHSCORE:" + str(global.high_score)


func _input(event):
	if not score_screen:
		return
	if $RestartTimer.is_stopped() and event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		$RestartTimer.start()
		$BlackScreen.visible = true


func _process(delta):
	if score_screen:
		pass
	elif Input.is_action_just_pressed("pause"):
		pause = not pause
		get_tree().paused = pause
		pause_label.visible = pause
		if pause:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func show_score(score, kills):
	if score > global.high_score:
		$HighScoreTimer.start()
		score_screen_new.visible = true
		global.save_high_score(score)
	
	screen_flash.flash(Color(0.75, 0.0, 0.0, 1.0), 0.5)
	$ScoreScreen.visible = true
	score_screen_score.text = "SCORE:" + str(score)
	score_screen_kills.text = "KILLS:" + str(kills)
	score_screen_high.text = "HIGHSCORE:" + str(global.high_score)
	$HUD.visible = false
	$PressTimer.start()
	score_screen = true


func update_health(health, max_health):
	health_bar.margin_right = bar_size * health / max_health
	if health < max_health / 5:
		if $HealthTimer.is_stopped():
			$HealthTimer.start()
	else:
		$HealthTimer.stop()
		health_container.visible = true


func update_score(score):
	score_counter.text = "SCORE  " + str(score)


func switch_health_bar():
	health_container.visible = not health_container.visible


func switch_press_text():
	score_screen_press_text.visible = not score_screen_press_text.visible


func flash_high_score():
	var color = Color(0.75, 0.0, 0.0)
	if flash_high_score:
		color = Color(1.0, 0.0, 0.0)
	score_screen_high.add_color_override("font_color", color)
	score_screen_new.add_color_override("font_color", color)
	flash_high_score = not flash_high_score
	


func restart():
	get_tree().reload_current_scene()
	get_tree().paused = false
