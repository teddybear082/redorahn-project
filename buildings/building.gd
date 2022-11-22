tool
extends XRToolsClimbable

signal shake_screen

export var health = 3
export var points = 100
export var occupants = 40
export var level = 0
export var can_shake = false
export var small = false

var fire_scene = preload("res://effects/fire.tscn")

var game = null
var destroy = false
var random = RandomNumberGenerator.new()

func _ready():
	random.randomize()
	$Origin/MeshDestroyed.rotation_degrees.y = random.randi() % 360
	$Origin/MeshDestroyed.scale.y += (random.randf() - 0.5) * 0.5
	if small:
		$Hitbox.set_collision_mask_bit(2, true)


func _process(delta):
	if not $HitTimer.is_stopped():
		$Origin/Mesh.translation.x = random.randf() - 0.5
		$Origin/Mesh.translation.z = random.randf() * 0.5
		
	if destroy:
		$Origin/Mesh.translation.y -= 8 * delta
		var height = $Origin/Mesh.translation.y + $Origin/Mesh.mesh.get_aabb().size.y - translation.y
		if height > 0.0 and can_shake:
			emit_signal("shake_screen")
		if height < 4.0:
			$Origin/MeshDestroyed.visible = true
		if height < 0.0:
			$Origin/Mesh.visible = false
			$SmokeParticles.emitting = false
			$CollapseSound.stop()
			if not small:
				$DownSound.play()
				emit_signal("shake_screen")
				if random.randi() % 100 < 12:
					var fire = fire_scene.instance()
					add_child(fire)
			destroy = false


func hit(area):
	var source = 0
	if small:
		source = 1
	if area.name == "LAttackArea" or area.name == "SmashAttackArea":
		area.find_parent("Monster").rumble_needed("left")
	elif area.name == "RAttackArea":
		area.find_parent("Monster").rumble_needed("right")
		
	health -= 1
	game.score(25)
	game.spawn_explosion(area.global_translation, source)
	evacuate(50)
	$Hitbox.set_deferred("monitoring", false)
	$HitTimer.start()
	if health <= 0:
		destroy = true
		set_collision_layer_bit(4, false)
		set_collision_layer_bit(5, false)
		$SmokeParticles.emitting = true
		game.score(points)
		game.kill(occupants)
		$CollapseSound.play()


func evacuate(luck):
	if occupants > 0 and random.randi() % 100 < luck:
		var loc = translation
		loc.x += random.randf() * 4.0 - 2.0
		loc.z += random.randf() * 4.0 - 2.0
		game.spawn_human(loc, level)
		occupants -= 1
		evacuate(luck / 2)


func _on_HitTimer_timeout():
	$Origin/Mesh.translation.x = 0.0
	$Origin/Mesh.translation.z = 0.0
	if health > 0:
		$Hitbox.monitoring = true
