extends CPUParticles

export var sound = 0

var audio_sources = [preload("res://sounds/building_hit.wav"),
 preload("res://sounds/explosion_small.wav"),
 preload("res://sounds/explosion_car.wav")]

var random = RandomNumberGenerator.new()

func _ready():
	random.randomize()
	restart()
	$FlareParticles.restart()
	$ExplosionSound.pitch_scale = 0.9 + (random.randf() * 0.2)
	if sound >= 0 and sound < audio_sources.size():
		$ExplosionSound.stream = audio_sources[sound]
	$ExplosionSound.play()
	
func remove():
	queue_free()
