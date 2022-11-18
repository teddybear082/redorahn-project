extends Area

var game = null
var monster = null
var velocity = Vector3.ZERO


func _physics_process(delta):
	if not monster:
		return
	velocity += (monster.translation - translation).normalized() * 0.02
	velocity = velocity.normalized()
	translation += velocity * 15.0 * delta
	#$Mesh.scale = Vector3(1.0, 1.0, 1.0) * $Timer.time_left / $Timer.wait_time


func impact(explode):
	if game and explode:
		game.spawn_explosion(translation, 1)
	$Mesh.visible = false
	$PlasmaParticles.emitting = false
	$CollisionShape.disabled = true


func collision(body):
	impact(true)


func remove():
	queue_free()
