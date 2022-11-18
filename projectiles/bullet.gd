extends Area

var velocity = Vector3.ZERO


func _ready():
	$FlareParticles.restart()


func _physics_process(delta):
	translation += velocity * delta


func impact():
	queue_free()


func collision(body):
	queue_free()


func remove():
	queue_free()
