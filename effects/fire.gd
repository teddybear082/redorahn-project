extends CPUParticles


func _ready():
	lifetime = 2.5 + randf()


func _on_FireTimer_timeout():
	queue_free()
