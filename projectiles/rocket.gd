extends Area

var game = null
var velocity = Vector3.ZERO
var speed = 0.0


func _ready():
	$FlareParticles.restart()


func _physics_process(delta):
	speed += delta
	speed = clamp(speed, 0.0, 40.0)
	translation += velocity * speed


func impact():
	if game:
		game.spawn_explosion(translation, 1)
	$Rocket.visible = false
	$SmokeParticles.emitting = false
	$CollisionShape.disabled = true


func collision(body):
	impact()


func remove():
	queue_free()
