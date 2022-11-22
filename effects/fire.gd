extends CPUParticles

var random = RandomNumberGenerator.new()

func _ready():
	random.randomize()
	lifetime = 2.5 + random.randf()


func _on_FireTimer_timeout():
	queue_free()
