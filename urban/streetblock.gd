extends MeshInstance

export var spawn_vehicles = true
export var spawn_humans = true


func _ready():
	if spawn_vehicles:
		correct_curve_coords($VehiclePath.curve)
	else:
		$VehiclePath.queue_free()
	
	if spawn_humans:
		correct_curve_coords($HumanPath.curve)
	else:
		$HumanPath.queue_free()
	


func correct_curve_coords(curve):
	for n in range(curve.get_point_count()):
		var pos = curve.get_point_position(n)
		pos = pos.rotated(Vector3.UP, rotation.y)
		pos += translation
		curve.set_point_position(n, pos)
