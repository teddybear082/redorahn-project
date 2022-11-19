extends Spatial

var broken_material = preload("res://natural/Egg_broken.material")
var ok_to_press_play : bool = false

onready var loading_screen = $LoadingScreen
onready var scene_holder = $intro_scene_holder
onready var cave = scene_holder.get_node("Cave")
onready var lava = cave.get_node("Lava")
onready var egg = scene_holder.get_node("Egg")
onready var cpu_particles = cave.get_node("CPUParticles")
onready var light = cave.get_node("OmniLight")
onready var start_sound = $StartSound
onready var interface = scene_holder.get_node("Viewport2Din3D").get_scene_instance()
onready var animation_player = interface.get_node("AnimationPlayer")
onready var press_timer = interface.get_node("PressTimer")
onready var music = interface.get_node("Music")
onready var press_start_icon = interface.get_node("Menu/PressStart")

func _ready():
	# Make 2D menu invisible at first until player is ready to continue
	scene_holder.visible = false
	
	# Set camera for loading screen
	loading_screen.set_camera($FPController/ARVRCamera)
	
	# Connect loading screen signal
	loading_screen.connect("continue_pressed", self, "_on_LoadingScreen_continue_pressed")

	# Connect button pressed signals on controllers
	$FPController/LeftHandController.connect("button_pressed", self, "_on_LeftHand_button_pressed")
	$FPController/RightHandController.connect("button_pressed", self, "_on_RightHand_button_pressed")

func _process(delta):
	lava.get_surface_material(0).uv1_offset.x += 0.005


func game_start_sequence():
	animation_player.play("start")
	start_sound.play()
	egg.set_surface_material(0, broken_material)
	press_start_icon.visible = false
	press_timer.stop()
	music.stop()
	yield(get_tree().create_timer(.3), "timeout")
	scene_holder.visible = false

func _on_LoadingScreen_continue_pressed():
	loading_screen.follow_camera = false
	loading_screen.visible = false
	yield(get_tree().create_timer(1.0), "timeout")
	scene_holder.stop_moving()
	if scene_holder.get_node("Viewport2Din3D").global_transform.origin.y < 1.5:
		scene_holder.get_node("Viewport2Din3D").global_transform.origin.y = 1.5
	cave.visible=false
	lava.visible=false
	egg.visible=false
	scene_holder.visible = true
	animation_player.play("jingle")
	yield(get_tree().create_timer(6), "timeout")
	ok_to_press_play = true
	cave.visible = true
	lava.visible = true
	egg.visible = true

func _on_LeftHand_button_pressed(_button):
	if animation_player.is_playing():
		return
	
	if ok_to_press_play == false:
		return
		
	game_start_sequence()
	
func _on_RightHand_button_pressed(_button):
	if animation_player.is_playing():
		return
	
	if ok_to_press_play == false:
		return
		
	game_start_sequence()
	
