extends Spatial

enum {STATE_IDLE, STATE_ATTACK_LEFT, STATE_ATTACK_RIGHT,
  STATE_ATTACK_SMASH, STATE_GRAB, STATE_ROAR, STATE_EAT, STATE_THROW, STATE_DEAD}

signal died
signal rumble_needed(side_string)

export var locked = false
export var roar = false
export (XRTools.Buttons) var roar_button : int = XRTools.Buttons.VR_BUTTON_BY
export (XRTools.Buttons) var grab_button : int = XRTools.Buttons.VR_GRIP
export (XRTools.Buttons) var fire_button : int = XRTools.Buttons.VR_BUTTON_BY
export (XRTools.Buttons) var attack_button : int = XRTools.Buttons.VR_TRIGGER
export (XRTools.Buttons) var HUD_button : int = XRTools.Buttons.VR_BUTTON_AX

var max_health = 1000
var health = max_health
var speed = 20.0
var camera_distance = 20.0
var state = STATE_IDLE
var grabbed_object = null
var fire = preload("res://effects/fire.tscn")
var able_to_torch: bool = true
var able_to_throw : bool = true

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
onready var throw_timer = $ThowTimer
onready var HUD_interface_viewport = $FPController/ARVRCamera/InterfaceViewport
onready var HUD_interface = HUD_interface_viewport.get_scene_instance()

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
			collider.add_child(fire_instance)
			able_to_torch = false
			torch_timer.start()
			if collider.is_in_group("humans"):
				collider.splat()
#	

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
		#object.transform.origin = Vector3.ZERO
		object.get_node("CollisionShape").disabled = true
		object.get_node("Origin").rotation = Vector3.ZERO
		object.get_node("AttackTimer").stop()
		object.get_node("DropTimer").stop()
		object.get_node("Hitbox").set_deferred("monitoring", false)
	grabbed_object = object
	able_to_throw = false
	throw_timer.start()
	rumble_needed("right")
	return true


func throw():
	if grabbed_object:
		#var vel = Vector3.FORWARD.rotated(Vector3.UP, grabbed_object.get_node("Origin").rotation.y)
		#var vel = -right_controller.transform.basis.z
		#var vel = -right_controller.transform.basis.z.rotated(Vector3.UP, player_model.rotation.y)
		var vel = -$FPController/ARVRCamera.transform.basis.z
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
		left_controller.set_rumble(0.1)
		right_controller.set_rumble(0.1)
	
	if button == attack_button:
		lattack_area.monitorable = true
		lattack_area.monitoring = true
		if HUD_interface.score_screen == true:
			HUD_interface.get_node("RestartTimer").start()
		
	if button == grab_button:
		lsmash_area.monitorable = true
		lsmash_area.monitoring = true
		
	if button == HUD_button:
		HUD_interface_viewport.visible = !HUD_interface_viewport.visible
		
		
func _on_right_controller_pressed(button):
	if button == roar_button:
		roar_sound.play()
		roar = true
		
	if button == attack_button:
		rattack_area.monitorable = true
		rattack_area.monitoring = true
		if HUD_interface.score_screen == true:
			HUD_interface.get_node("RestartTimer").start()
		
	if button == grab_button:
		if grab_raycast:
			if grab_raycast.is_colliding():
				grab(grab_raycast.get_collider())
	
			
func _on_left_controller_released(button):
	if button == fire_button:
		fire_raycast.enabled = false
		$FPController/ARVRCamera/FireParticles.visible = false
		left_controller.set_rumble(0.0)
		right_controller.set_rumble(0.0)
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
		if grabbed_object and able_to_throw:
			throw()

func rumble_needed(side: String):
	if side == "left":
		left_controller.set_rumble(.3)
		yield(get_tree().create_timer(.3), "timeout")
		left_controller.set_rumble(0.0)		
	
	if side == "right":
		right_controller.set_rumble(.3)
		yield(get_tree().create_timer(.3), "timeout")
		right_controller.set_rumble(0.0)
	
	else:
		print("Wrong string for rumble_needed function")
		return	
			
func _play_step_sound():
	step_sound.play()


func _on_EatingArea_body_entered(body):
	if body.is_in_group("humans"):
		eat()
		eat_sound.play()
		rumble_needed("right")
		grabbed_object=null
		


func _on_TorchTimer_timeout():
	able_to_torch = true


func _on_ThowTimer_timeout():
	able_to_throw = true
	

func _on_RoarSound_finished():
	roar = false
