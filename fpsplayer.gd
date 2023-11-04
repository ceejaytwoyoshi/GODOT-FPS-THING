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

@onready var neck = $Neck
@onready var head = $Neck/Head
@onready var camera_3d = $Neck/Head/Camera3D
@onready var collision_shape_standing = $CollisionShape_STANDING
@onready var collision_shape_crouching = $CollisionShape_CROUCHING
@onready var head_checker = $Neck/Head/HeadChecker
@onready var slope_checker = $SlopeChecker



var mouseSens = 0.15
var camAngl = 0.0
var targetAngl = 0.0
var viewRollAmnt = 1
var viewRollSpeed = 0.1

const DEFAULT_HEIGHT = 2.0
const CROUCH_HEIGHT = 1.0
var crouchSpeed = 10
var crouchDepth = -0.75

var slideTime = 0.0
var slideTimeMax = 1.5
var slideVec = Vector2.ZERO


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
		if currentState == CharacterStates.SLIDING:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouseSens))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouseSens))
		
		head.rotate_x(deg_to_rad(-event.relative.y * mouseSens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	head.rotation.z = lerp(head.rotation.z, 0.0, delta * 8.0)
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
				if Input.is_action_pressed("sprint") and (!input_dir == Vector2.DOWN and input_dir.x == 0):
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
					if direction.length() <= 0.5:
						currentState = CharacterStates.IDLE
			else:
				currentState = CharacterStates.FALLING
		CharacterStates.SPRINTING:
			if is_on_floor() and direction.length() > 0.5:
				currentSpeed = SSPEED
				if Input.is_action_just_released("sprint"):
					if direction.length() > 0.5:
						currentState = CharacterStates.WALKING
					if direction.length() <= 0.5:
						currentState = CharacterStates.IDLE
				if Input.is_action_just_pressed("ui_accept") and input_dir != Vector2.ZERO:
					currentState = CharacterStates.JUMPING
				if Input.is_action_pressed("crouch"):
					currentState = CharacterStates.SLIDING
					slideTime = slideTimeMax
					slideVec = input_dir
			else:
				currentState = CharacterStates.FALLING
		CharacterStates.SLIDING:
			slideTime -= delta
			
			direction = (transform.basis * Vector3(slideVec.x, 0.0, slideVec.y)).normalized() 
			
			head.rotation.z = lerp(camera_3d.rotation.z, -deg_to_rad(15.0), delta * 5.0)
			head.position.y = lerp(head.position.y, 1.5 + crouchDepth, delta * 8.0)
			collision_shape_standing.disabled = true
			collision_shape_crouching.disabled = false
			velocity.x = direction.x * slideTime 
			velocity.z = direction.z * slideTime
			
			
			if slideTime <= 0.0 or Input.is_action_just_released("crouch") and !head_checker.is_colliding():
				slideTime = 0.0 
				if direction.length() <= 0.5:
					currentState = CharacterStates.IDLE
				elif direction.length() > 0.5:
					currentState = CharacterStates.WALKING
				self.rotation.y += neck.rotation.y
				neck.rotation.y = 0.0
				head.rotation.z = lerp(head.rotation.z, 0.0, delta * 8.0)
			
			if slideTime <= 0.0 and head_checker.is_colliding():
				await get_tree().create_timer(0.001).timeout
				currentState = CharacterStates.CROUCHING
			
			if slope_checker.is_colliding():
				slideTime += 0.25
			
			if slideTime <= 0.0 and Input.is_action_just_pressed("crouch"):
				slideTime = 0.0
				currentState = CharacterStates.CROUCHING
				if Input.is_action_just_released("crouch"):
					if direction.length() <= 0.5:
						currentState = CharacterStates.IDLE
					elif direction.length() > 0.5:
						currentState = CharacterStates.WALKING
				self.rotation.y += neck.rotation.y
				neck.rotation.y = 0.0
				head.rotation.z = lerp(head.rotation.z, 0.0, delta * 8.0)
			
			
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
				
				if Input.is_action_pressed("sprint") and Input.is_action_pressed("crouch") and input_dir != Vector2.ZERO:
					currentState = CharacterStates.SLIDING
					slideTime = slideTimeMax
					slideVec = input_dir
			else:
				velocity.y -= gravity * delta
	
	if slideTime >= slideTimeMax:
		slideTime = slideTimeMax
	
	# MOVEMENT AND SHIT

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
	
	print(slideTime)
	print("State: ", stateNames[currentState])
	
	# FOV shit
	var velocityClamped = clamp(velocity.length(), 0.5, SSPEED * 2)
	var targetFOV = playerFOV + FOVCHANGE * velocityClamped
	camera_3d.fov = lerp(camera_3d.fov, targetFOV, delta * 5.0)


func _on_slide_timer_timeout():
	pass # Replace with function body.
