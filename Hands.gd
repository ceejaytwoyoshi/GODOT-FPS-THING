extends Node3D


@onready var fpsplayer = $"../../../../../.."
@export var viewmodelBobEnable = true
@export var viewmodelTilt = true
@export var viewmodelSwayEnable = true

# viewmodel bob variables

var bobTime = 0.0
const BOB_FREQ = 1.5
@export var bobAmp = 0.010

# viewmodel tilt variables

var vmodelTiltAngl = 0.0
var targetAngl = 0.0
var vmodelTiltAmnt = 1.25
var vmodelTiltSpeed = 0.1

# viewmodel sway variables

var weaponSwayAmt = 0.015
var mouseInput: Vector2

func _input(event):
	if event is InputEventMouseMotion:
		mouseInput = -event.relative

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	if fpsplayer.currentState == fpsplayer.CharacterStates.CROUCHING or fpsplayer.currentState == fpsplayer.CharacterStates.SLIDING:
		get_tree().create_tween().tween_property(self,"rotation:z", deg_to_rad(5.5), 0.50)
	else:
		get_tree().create_tween().tween_property(self,"rotation:z", deg_to_rad(0.0), 0.50)
	
	if viewmodelBobEnable:
		if fpsplayer.currentState == fpsplayer.CharacterStates.SPRINTING:
			bobTime += (delta * 2 * fpsplayer.velocity.length() * float(fpsplayer.is_on_floor())) + 0.01
		else:
			bobTime += (delta * fpsplayer.velocity.length() * float(fpsplayer.is_on_floor())) + 0.01
		transform.origin = _viewmodelBob(bobTime)
	if viewmodelTilt:
		_viewmodelTilt(input_dir, delta)
	if viewmodelSwayEnable:
		_viewmodelSway(delta)
	


func _viewmodelBob(time) -> Vector3:
	var pos = Vector3.ZERO
	if fpsplayer.currentState == fpsplayer.CharacterStates.CROUCHING:
		pos.y = sin(time * BOB_FREQ) * (bobAmp + 0.01)
		pos.x = cos(time * BOB_FREQ / 2) * (bobAmp + 0.02)
	else:
		pos.y = sin(time * BOB_FREQ) * bobAmp
		pos.x = cos(time * BOB_FREQ / 2) * (bobAmp + 0.02)
	
	return pos

func _viewmodelTilt(inputDir, delta):
	targetAngl = inputDir.x * vmodelTiltAmnt * delta
	vmodelTiltAngl = lerp(vmodelTiltAngl, -targetAngl, vmodelTiltSpeed)
	rotation.z = vmodelTiltAngl

func _viewmodelSway(delta):
	mouseInput = lerp(mouseInput, Vector2.ZERO, 10*delta)
	rotation.x = lerp(rotation.x, mouseInput.y * weaponSwayAmt, 7 * delta)
	rotation.x = clamp(rotation.x, deg_to_rad(-55), deg_to_rad(55))
	rotation.y = lerp(rotation.y, mouseInput.x * weaponSwayAmt, 7 * delta)
	rotation.y = clamp(rotation.y, deg_to_rad(-35), deg_to_rad(35))
