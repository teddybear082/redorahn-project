# This script rotates a screen in front of the player dynamically.  The screen, a child of this holder, has to be rotated 180 degrees in the scene tree.

extends Spatial
export (NodePath) var vrCamera_path
export var time_to_move : float = 0.5
export var distance : float = 3.0
export var use_definite_follow_time : bool = false
export var definite_follow_time_secs : float = 1.0

onready var vrCamera = get_node(vrCamera_path)

var currentPosition: Vector3
var targetPosition: Vector3
var movePosition : Vector3
var moving = false
var moveTimer = 0.0

func _ready():
	var viewDir = -vrCamera.global_transform.basis.z;
	var camPos = vrCamera.global_transform.origin;
	currentPosition = camPos + viewDir * distance;
	targetPosition = currentPosition;
	movePosition = currentPosition;
	
	look_at_from_position(currentPosition, camPos, Vector3(0,1,0));
	
	# If use definite follow time, after time expires, stop moving object; this can be useful to ensure screen is in front of player at start
	# of scene but then allow the player to move around the screen as necessary.
	
	if use_definite_follow_time == true:
		yield(get_tree().create_timer(definite_follow_time_secs), "timeout")
		set_process(false)

func _process(dt):
	var viewDir = -vrCamera.global_transform.basis.z;
	viewDir.y = 0.0;
	viewDir = viewDir.normalized();
	
	var camPos = vrCamera.global_transform.origin;

	targetPosition = camPos + viewDir * distance;
	var distToTarget = (targetPosition - currentPosition).length();
	if moving:
		currentPosition = currentPosition + (movePosition - currentPosition) * dt;
		if (distToTarget < 0.05):
			moving = false;

			
	if (distToTarget > 0.5):
		moveTimer += dt;
	else:
		moveTimer = 0.0;
			
	if (moveTimer > time_to_move):
		moving = true;
		movePosition = targetPosition;

	look_at_from_position(currentPosition, camPos, Vector3(0,1,0));
	
		
func stop_moving():
	set_process(false)
