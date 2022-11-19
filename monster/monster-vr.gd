extends Spatial

enum {STATE_IDLE, STATE_ATTACK_LEFT, STATE_ATTACK_RIGHT,
  STATE_ATTACK_SMASH, STATE_GRAB, STATE_ROAR, STATE_EAT, STATE_THROW, STATE_DEAD}

signal died

export var locked = false
export var roar = false
export (XRTools.Buttons) var roar_button : int = XRTools.Buttons.VR_BUTTON_BY
export (XRTools.Buttons) var grab_button : int = XRTools.Buttons.VR_GRIP
export (XRTools.Buttons) var fire_button : int = XRTools.Buttons.VR_BUTTON_BY
export (XRTools.Buttons) var attack_button : int = XRTools.Buttons.VR_TRIGGER

var max_health = 1000
var health = max_health
var speed = 20.0
var camera_distance = 20.0
var state = STATE_IDLE
var grabbed_object = null
var fire = preload("res://effects/fire.tscn")
var able_to_torch: bool = true

onready var grab_area = $FPController/monster/Armature/Skeleton/RightHandAnchor/GrabArea
onready var grab_raycast = grab_area.get_node("GrabRayCast")
onready var lstomp_area = $FPController/monster/Armature/Skeleton/LeftFootAnchor/LStompArea
onready var rstomp_area = $FPController/monster/Armature/Skeleton/RightFootAnchor/RStompArea
onready var lattack_area = $FPController/monster/Armature/Skeleton/LeftHandAnchor/LAttackArea
onready var rattack_area = $FPController/monster/Armature/Skeleton/RightHandAnchor/RAttackArea
onready var lsmash_area = $FPController/monster/Armature/Skeleton/LeftHandAnchor/LAttackArea/SmashAttackArea
onready var player = $FPController/monster/AnimationPlayer
onready var player_body = $FPController/PlayerBody
onready var player_model = $FPController/monster
onready var left_controller : ARVRController = $FPController/LeftHandController
onready var right_controller : ARVRController = $FPController/RightHandController
onready var step_sound = $StepSound
onready var roar_sound = $DieSound
onready var fire_sound = $FireSound
onready var eat_sound = $EatSound
onready var fire_raycast = $FPController/ARVRCamera/FireRayCast
onready var torch_timer = $TorchTimer


func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player_body.set_player_radius(2)
	player_body.override_player_height(self, 4.25)
	
	# Shrink head bone to make robot avatar's head invisible to player
	var head_bone_pose = player_model.get_node("Armature/Skeleton").get_bone_pose(3)
	var new_head_basis = head_bone_pose.basis.scaled(Vector3(0,0,0))
	player_model.get_node("Armature/Skeleton").set_bone_pose(3, Transform(new_head_basis, head_bone_pose.origin))
	player_model.get_node("Armature/Skeleton").set_bone_rest(3, Transform(new_head_basis, head_bone_pose.origin))
	
	# Connect controller signals
	left_controller.connect("button_pressed", self, "_on_left_controller_pressed")
	right_controller.connect("button_pressed", self, "_on_right_controller_pressed")
	left_controller.connect("button_release", self, "_on_left_controller_released")
	right_controller.connect("button_release", self, "_on_right_controller_released")
	
	# Connect procedural step signals
	player_model.connect("avatar_procedural_step_taken", self, "_play_step_sound")
	
#func _unhandled_input(event):
#	if event is InputEventMouseMotion:
#		var mouse_motion = event.relative * 0.1
#		$CameraPivot.rotation_degrees.x -= mouse_motion.y
#		$CameraPivot.rotation_degrees.y -= mouse_motion.x
#		$CameraPivot.rotation_degrees.x = clamp($CameraPivot.rotation_degrees.x, -75.0, 25.0)


func _physics_process(delta):
	if fire_raycast.enabled and fire_raycast.is_colliding() and able_to_torch:
		if fire_raycast.get_collider() is StaticBody or fire_raycast.get_collider() is KinematicBody:
			var collider = fire_raycast.get_collider()
			var fire_instance = fire.instance()
			fire_instance.scale_amount = 3
			#fire_instance.global_transform.origin = fire_raycast.get_collision_point()
			collider.add_child(fire_instance)
			able_to_torch = false
			torch_timer.start()
			if collider.is_in_group("humans"):
				collider.splat()
#	# Camera update
#	var camera_speed = 3.0
#	$CameraPivot.rotation_degrees.x -= Input.get_action_strength("camera_down") * camera_speed
#	$CameraPivot.rotation_degrees.x += Input.get_action_strength("camera_up") * camera_speed
#	$CameraPivot.rotation_degrees.y -= Input.get_action_strength("camera_right") * camera_speed
#	$CameraPivot.rotation_degrees.y += Input.get_action_strength("camera_left") * camera_speed
#	$CameraPivot.rotation_degrees.x = clamp($CameraPivot.rotation_degrees.x, -75.0, 25.0)
#
#	var target = Vector3.BACK.rotated(Vector3.UP, $CameraPivot.rotation.y) * 3.0
#	target += Vector3.FORWARD.rotated(Vector3.UP, $Origin.rotation.y) * 5.0
#
#	var vel = (target - $CameraPivot.translation) * 0.025
#	$CameraPivot.translation += vel
#	$CameraPivot.translation.y = 2.5
#
#	var time = $ShakeTimer.time_left
#	time = clamp(time, 0.0, 1.0)
#	time *= 0.25
#	$CameraPivot/Camera.translation = Vector3(randf() * time, randf() * time, camera_distance + randf() * time)
#
#	# Monster update
#	var velocity = Vector3.ZERO
#	velocity.y = -10
#	var direction = Vector3.ZERO
#
#	if state != STATE_GRAB:
#		grab_area.monitorable = false
#
#	if state != STATE_ROAR:
#		roar = false
#
#	match state:
#		STATE_IDLE:
#			player.playback_speed = 1.3
#			"""
#			direction.z += Input.get_axis("move_forward", "move_back")
#			direction.x += Input.get_axis("move_left", "move_right")
#			"""
#			direction.z -= Input.get_action_strength("move_forward")
#			direction.z += Input.get_action_strength("move_back")
#			direction.x -= Input.get_action_strength("move_left")
#			direction.x += Input.get_action_strength("move_right")
#
#			if direction != Vector3.ZERO:
#				player.play("walk-loop")
##				direction = direction.normalized()
##				direction = direction.rotated(Vector3.UP, $CameraPivot.rotation.y)
##				$Origin.look_at(translation + direction, Vector3.UP)
##				velocity += direction * speed
#			else:
#				player.play("idle-loop")
#
#
#			if Input.is_action_just_pressed("attack"):
#				set_state(STATE_ATTACK_LEFT, "attack-left")
#			elif Input.is_action_just_pressed("smash"):
#				set_state(STATE_ATTACK_SMASH, "smash")
#			elif Input.is_action_just_pressed("grab"):
#				if not perform_grab_action():
#					set_state(STATE_GRAB, "grab")
#			elif Input.is_action_just_pressed("roar"):
#				set_state(STATE_ROAR, "roar")
#
#		STATE_ATTACK_LEFT:
#			player.playback_speed = 2.4
#			if Input.is_action_just_pressed("attack") and not locked:
#				set_state(STATE_ATTACK_RIGHT, "attack-right")
#			if not player.is_playing():
#				set_state(STATE_IDLE)
#
#		STATE_ATTACK_RIGHT:
#			player.playback_speed = 2.4
#			if Input.is_action_just_pressed("attack") and not locked:
#				set_state(STATE_ATTACK_LEFT, "attack-left")
#			if not player.is_playing():
#				set_state(STATE_IDLE)
#
#		STATE_ATTACK_SMASH:
#			player.playback_speed = 2.4
#			if Input.is_action_just_pressed("smash") and not locked:
#				player.stop()
#				set_state(STATE_ATTACK_SMASH, "smash")
#			if not player.is_playing():
#				set_state(STATE_IDLE)
#
#		STATE_GRAB:
#			player.playback_speed = 1.0
#			if Input.is_action_just_pressed("grab") and not locked:
#				perform_grab_action()
#			if not player.is_playing():
#				set_state(STATE_IDLE)
#
#		STATE_ROAR:
#			player.playback_speed = 1.25
#			if not player.is_playing():
#				set_state(STATE_IDLE)
#
#		STATE_EAT:
#			player.playback_speed = 2.0
#			if not player.is_playing():
#				set_state(STATE_IDLE)
#
#		STATE_THROW:
#			player.playback_speed = 1.5
#			if not player.is_playing():
#				set_state(STATE_IDLE)
#
#		STATE_DEAD:
#			player.playback_speed = 1.0
#
#		_:
#			if not player.is_playing():
#				set_state(STATE_IDLE)
#
#	move_and_slide(velocity)


func perform_grab_action():
	if grabbed_object:
		if grabbed_object.is_in_group("humans"):
			set_state(STATE_EAT, "eat")
		else:
			set_state(STATE_THROW, "throw")
		return true
	else:
		return false


func set_state(new_state, anim = null):
	if new_state == STATE_DEAD and state != STATE_DEAD:
		emit_signal("died")
	if anim:
		player.play(anim)
	state = new_state
	locked = true
	lstomp_area.monitorable = false
	rstomp_area.monitorable = false


func grab(object):
	if grabbed_object:
		return false
	
	object.get_parent().call_deferred("remove_child", object)
	grab_area.call_deferred("add_child", object)
	object.translation = Vector3.ZERO
	if object.is_in_group("humans"):
		object.state = object.STATE_GRABBED
		object.get_node("Origin").rotation = Vector3.ZERO
		object.get_node("Hitbox").set_deferred("monitoring", false)
	if object.is_in_group("vehicles"):
		object.state = object.STATE_GRABBED
		object.transform.origin = Vector3.ZERO
		object.get_node("CollisionShape").disabled = true
		object.get_node("Origin").rotation = Vector3.ZERO
		object.get_node("AttackTimer").stop()
		object.get_node("DropTimer").stop()
		object.get_node("Hitbox").set_deferred("monitoring", false)
	grabbed_object = object
	return true


func throw():
	if grabbed_object:
		var vel = Vector3.FORWARD.rotated(Vector3.UP, grabbed_object.get_node("Origin").rotation.y)
		vel *= 150.0
		vel.y = 50.0
		grabbed_object.throw(grab_area.global_translation, vel)
		grabbed_object = null


func eat():
	if grabbed_object:
		if grabbed_object.alien:
			health += 100
		else:
			health += 30
		grabbed_object.eat()
		grabbed_object = null
		health = min(health, max_health)


func shake():
	$ShakeTimer.start()


func hit(area):
	if state == STATE_DEAD:
		return
	
	if area.get_collision_layer_bit(10):
		health -= 1
		area.impact()

	if area.get_collision_layer_bit(11):
		health -= 10
		area.impact()
	
	if area.get_collision_layer_bit(12):
		health -= 3
		area.impact()
	
	if area.get_collision_layer_bit(13):
		health -= 50
		area.impact(true)
	
	health = max(health, 0)
	
	if health == 0:
		set_state(STATE_DEAD, "die")


func _on_left_controller_pressed(button):
	if button == fire_button:
		$FPController/ARVRCamera/FireParticles.visible = true
		fire_sound.play()
		fire_raycast.enabled = true
	
	if button == attack_button:
		lattack_area.monitorable = true
		lattack_area.monitoring = true
		
	if button == grab_button:
		lsmash_area.monitorable = true
		lsmash_area.monitoring = true
		
		
func _on_right_controller_pressed(button):
	if button == roar_button:
		roar_sound.play()
		
	if button == attack_button:
		rattack_area.monitorable = true
		rattack_area.monitoring = true
		
	if button == grab_button:
		if grab_raycast:
			if grab_raycast.is_colliding():
				grab(grab_raycast.get_collider())
	
			
func _on_left_controller_released(button):
	if button == fire_button:
		fire_raycast.enabled = false
		$FPController/ARVRCamera/FireParticles.visible = false
		fire_sound.stop()
		
	if button == attack_button:
		lattack_area.monitorable = false
		lattack_area.monitoring = false
	
	if button == grab_button:
		lsmash_area.monitorable = false
		lsmash_area.monitoring = false
		
	
func _on_right_controller_released(button):
	if button == attack_button:
		rattack_area.monitorable = false
		rattack_area.monitoring = false
		
	if button == grab_button:
		if grabbed_object:
			throw()
			
			
func _play_step_sound():
	step_sound.play()


func _on_EatingArea_body_entered(body):
	if body.is_in_group("humans"):
		grabbed_object=null
		eat_sound.play()
		body.queue_free()


func _on_TorchTimer_timeout():
	able_to_torch = true
