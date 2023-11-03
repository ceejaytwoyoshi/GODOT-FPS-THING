extends CharacterBody3D


const WSPEED = 5.0
const SSPEED = 7.5
const CSPEED = 3.0
const JUMP_VELOCITY = 4.5

var playerFOV = 100
const FOVCHANGE = 1.5

@onready var currentSpeed = WSPEED

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@onready var camera_3d = $Head/Camera3D
@onready var collision_shape_standing = $CollisionShape_STANDING
@onready var collision_shape_crouching = $CollisionShape_CROUCHING
@onready var head_checker = $Head/HeadChecker



var camRotation = Vector2(0,0)
var mouseSens = 0.001
var camAngl = 0.0
var targetAngl = 0.0
var viewRollAmnt = 1
var viewRollSpeed = 0.1

const DEFAULT_HEIGHT = 2.0
const CROUCH_HEIGHT = 1.0
var crouchSpeed = 10
var crouchDepth = -0.75

var direction = Vector3.ZERO

enum CharacterStates { IDLE, WALKING, JUMPING, FALLING, SPRINTING, CROUCHING, SLIDING }
var currentState = CharacterStates.IDLE
var stateNames = {
	CharacterStates.IDLE: "IDLE",
	CharacterStates.WALKING: "WALKING",
	CharacterStates.JUMPING: "JUMPING",
	CharacterStates.FALLING: "FALLING",
	CharacterStates.SPRINTING: "SPRINTING",
	CharacterStates.CROUCHING: "CROUCHING",
	CharacterStates.SLIDING: "SLIDING"
}


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		var MouseEvent = event.relative * mouseSens
		CameraLook(MouseEvent)

func CameraLook(Movement: Vector2):
	camRotation += Movement
	camRotation.y = clamp(camRotation.y, -1.5, 1.5)
	
	transform.basis = Basis()
	head.transform.basis = Basis()
	
	rotate_object_local(Vector3(0,1,0), -camRotation.x) # rotates y
	head.rotate_object_local(Vector3(1,0,0), -camRotation.y) # rotates x

func _physics_process(delta):
	match currentState:
		CharacterStates.IDLE:
			if is_on_floor():
				head.position.y = lerp(head.position.y, 1.5, delta * 8.0)
				collision_shape_standing.disabled = false
				collision_shape_crouching.disabled = true
				velocity.x = 0.0
				velocity.z = 0.0
				
				if direction.length() > 0.5:
					currentState = CharacterStates.WALKING
				else:
					currentState = CharacterStates.IDLE
				
				if Input.is_action_pressed("crouch"):
					currentState = CharacterStates.CROUCHING
				
				if Input.is_action_just_pressed("ui_accept"):
					currentState = CharacterStates.JUMPING
			else:
				currentState = CharacterStates.FALLING
		CharacterStates.WALKING:
			if is_on_floor():
				head.position.y = lerp(head.position.y, 1.5, delta * 8.0)
				collision_shape_standing.disabled = false
				collision_shape_crouching.disabled = true
				currentSpeed = WSPEED
				if direction.length() > 0.5:
					currentState = CharacterStates.WALKING
				else:
					currentState = CharacterStates.IDLE
				if Input.is_action_pressed("sprint"):
					currentState = CharacterStates.SPRINTING
				if Input.is_action_just_pressed("ui_accept"):
					currentState = CharacterStates.JUMPING
				if Input.is_action_pressed("crouch"):
					currentState = CharacterStates.CROUCHING
			else:
				currentState = CharacterStates.FALLING
		CharacterStates.CROUCHING:
			if is_on_floor():
				currentSpeed = CSPEED
				head.position.y = lerp(head.position.y, 1.5 + crouchDepth, delta * 8.0)
				collision_shape_standing.disabled = true
				collision_shape_crouching.disabled = false
				if Input.is_action_just_pressed("ui_accept"):
					currentState = CharacterStates.JUMPING
				if Input.is_action_just_released("crouch") and !head_checker.is_colliding():
					if direction.length() > 0.5:
						currentState = CharacterStates.WALKING
					if direction.length() == 0.0:
						currentState = CharacterStates.IDLE
			else:
				currentState = CharacterStates.FALLING
		CharacterStates.SPRINTING:
			if is_on_floor() and direction.length() > 0.5:
				currentSpeed = SSPEED
				if Input.is_action_just_released("sprint"):
					if direction.length() > 0.5:
						currentState = CharacterStates.WALKING
					if direction.length() == 0.0:
						currentState = CharacterStates.IDLE
				if Input.is_action_just_pressed("ui_accept"):
					currentState = CharacterStates.JUMPING
			else:
				currentState = CharacterStates.FALLING
		CharacterStates.JUMPING:
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
			else:
				currentState = CharacterStates.FALLING
		CharacterStates.FALLING:
			if is_on_floor():
				velocity.y = 0
				if direction.length() > 0.5:
					currentState = CharacterStates.WALKING
				else:
					currentState = CharacterStates.IDLE
			else:
				velocity.y -= gravity * delta
	
	
	
	# MOVEMENT AND SHIT
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*10.0)
	if is_on_floor():
		if direction:
			velocity.x = direction.x * currentSpeed 
			velocity.z = direction.z * currentSpeed
		else:
			velocity.x = lerp(velocity.x, direction.x * currentSpeed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * currentSpeed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * currentSpeed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * currentSpeed, delta * 3.0)
	
	move_and_slide()
	
	#View Tilt
	
	targetAngl = input_dir.x * viewRollAmnt * delta
	camAngl = lerp(camAngl, -targetAngl, viewRollSpeed)
	camera_3d.rotation.z = camAngl
	
	print("State: ", stateNames[currentState])
	
	# FOV shit
	var velocityClamped = clamp(velocity.length(), 0.5, SSPEED * 2)
	var targetFOV = playerFOV + FOVCHANGE * velocityClamped
	camera_3d.fov = lerp(camera_3d.fov, targetFOV, delta * 5.0)
