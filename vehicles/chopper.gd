extends "res://vehicles/vehicle.gd"


func _physics_process(delta):
	if state != STATE_PARKED and occupants > 0:
		$Origin/HelixMesh.rotation_degrees.y += 720.0 * delta
		$Origin/RotorMesh.rotation_degrees.x += 720.0 * delta
	
	if state != STATE_CHOPPER:
		$ChopperSound.stop()
