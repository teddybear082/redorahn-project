extends "res://vehicles/vehicle.gd"

var siren = false
onready var red_light = $Origin/RedLight
onready var blue_light = $Origin/BlueLight


func _ready():
	random.randomize()
	if random.randi() % 100 < 100:
		siren = true
	stop_siren()


func _process(delta):
	if siren and state == STATE_CHASE and $SirenTimer.is_stopped():
		start_siren()
	elif state != STATE_CHASE:
		stop_siren()


func start_siren():
	red_light.visible = true
	blue_light.visible = false
	$SirenSound.play()
	$SirenTimer.start()


func stop_siren():
	red_light.visible = false
	blue_light.visible = false
	$SirenSound.stop()
	$SirenTimer.stop()

func switch_siren():
	red_light.visible = !red_light.visible
	blue_light.visible = !blue_light.visible

