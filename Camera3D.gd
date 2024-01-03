extends Camera3D

@onready var fpsplayer = $"../../../.."
@onready var animation_player = %AnimationPlayer


var playerFOV = 100
const FOVCHANGE = 1.5


var camAngl = 0.0
var targetAngl = 0.0
var viewRollAmnt = 35.0
var viewRollSpeed = 0.1



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	var velocityClamped = clamp(fpsplayer.velocity.length(), 0.5, fpsplayer.currentSpeed * 2)
	var targetFOV = playerFOV + FOVCHANGE * velocityClamped
	fov = lerp(fov, targetFOV, delta * 10.5)
	
	if fpsplayer.canMove:
		get_tree().create_tween().tween_property(self,"rotation:z", -deg_to_rad(viewRollAmnt * input_dir.x), 1.5)
	
	if fpsplayer.currentState == fpsplayer.CharacterStates.SLIDING:
		get_tree().create_tween().tween_property(self,"rotation:z", -deg_to_rad(2.5), 1.15)
	else:
		get_tree().create_tween().tween_property(self,"rotation:z", -deg_to_rad(0.0), 0.05)
	
	
	
	print(viewRollAmnt * input_dir.x)
