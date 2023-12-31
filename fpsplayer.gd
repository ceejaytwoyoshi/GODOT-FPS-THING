extends CharacterBody3D


const WSPEED = 6.0
const SSPEED = 7.0
const CSPEED = 3.0
const JUMP_VELOCITY = 4.5


var canMove = true

@onready var currentSpeed = WSPEED

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var neck = $Neck
@onready var head = $Neck/Head
@onready var camera_3d = $Neck/Head/CameraShake/Camera3D
@onready var collision_shape_standing = $CollisionShape_STANDING
@onready var collision_shape_crouching = $CollisionShape_CROUCHING
@onready var head_checker = $Neck/Head/HeadChecker
@onready var slope_checker = $SlopeChecker
@onready var hands = $Neck/Head/Camera3D/WeaponManager/Hands


var mouseSens = 0.15

const DEFAULT_HEIGHT = 2.0
const CROUCH_HEIGHT = 1.0
var crouchSpeed = 10
var crouchDepth = -0.75

var slideDecelRate = 15.0
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
		head.rotate_x(deg_to_rad(-event.relative.y * mouseSens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		if currentState == CharacterStates.SLIDING:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouseSens))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouseSens))

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var velocityRounded = snapped(velocity.length(), 0.001)
	head.rotation.z = lerp(head.rotation.z, 0.0, delta * 8.0)
	head.position.y = lerp(head.position.y, 1.5, delta * 8.0)
	collision_shape_standing.disabled = false
	collision_shape_crouching.disabled = true
	match currentState:
		CharacterStates.IDLE:
			if is_on_floor():
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
				currentSpeed = WSPEED
				if direction.length() > 0.5:
					currentState = CharacterStates.WALKING
				else:
					currentState = CharacterStates.IDLE
				if Input.is_action_pressed("sprint") and (!input_dir == Vector2.DOWN):
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
					slideVec = input_dir
			else:
				currentState = CharacterStates.FALLING
		CharacterStates.SLIDING:
			if is_on_floor():
				canMove = false
				direction = (transform.basis * Vector3(slideVec.x, 0.0, slideVec.y)).normalized() 
				
				head.position.y = lerp(head.position.y, 1.5 + crouchDepth, delta * 8.0)
				collision_shape_standing.disabled = true
				collision_shape_crouching.disabled = false
				velocity.x = (direction.x * currentSpeed) - (delta)
				velocity.z = (direction.z * currentSpeed) - (delta)
				
				
				if velocityRounded <= 1.750 or Input.is_action_just_released("crouch") and !head_checker.is_colliding():
					if direction.length() <= 0.5:
						currentState = CharacterStates.IDLE
					elif direction.length() > 0.5:
						currentState = CharacterStates.WALKING
					self.rotation.y += neck.rotation.y
					neck.rotation.y = 0.0
					head.rotation.z = lerp(head.rotation.z, 0.0, delta * 8.0)
					canMove = true
				
				if velocityRounded <= 1.750 and head_checker.is_colliding():
					await get_tree().create_timer(0.001).timeout
					currentState = CharacterStates.CROUCHING
				
				if slope_checker.is_colliding():
					currentSpeed += (delta * 2.5)
				else:
					currentSpeed -= delta
				
				if velocityRounded <= 1.750 and Input.is_action_pressed("crouch"):
					currentState = CharacterStates.CROUCHING
					if Input.is_action_just_released("crouch"):
						if direction.length() <= 0.5:
							currentState = CharacterStates.IDLE
						elif direction.length() > 0.5:
							currentState = CharacterStates.WALKING
					self.rotation.y += neck.rotation.y
					neck.rotation.y = 0.0
					head.rotation.z = lerp(head.rotation.z, 0.0, delta)
					canMove = true
			else:
				currentState = CharacterStates.FALLING
		CharacterStates.JUMPING:
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
			else:
				currentState = CharacterStates.FALLING
		CharacterStates.FALLING:
			if is_on_floor():
				if Input.is_action_pressed("sprint") and Input.is_action_pressed("crouch") and input_dir != Vector2.ZERO:
					currentState = CharacterStates.SLIDING
					slideVec = input_dir
				else:
					if direction.length() > 0.5:
						currentState = CharacterStates.WALKING
						direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*10.0)
					else:
						currentState = CharacterStates.IDLE
						direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*10.0)
					canMove = true
				
			else:
				velocity.y -= gravity * delta
	
	
	# MOVEMENT AND SHIT

	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*10.0)
	if is_on_floor():
		if direction and canMove:
			velocity.x = direction.x * currentSpeed
			velocity.z = direction.z * currentSpeed
		else:
			velocity.x = lerp(velocity.x, direction.x * currentSpeed, delta * 5.0)
			velocity.z = lerp(velocity.z, direction.z * currentSpeed, delta * 5.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * currentSpeed, delta * 5.0)
		velocity.z = lerp(velocity.z, direction.z * currentSpeed, delta * 5.0)
	
	move_and_slide()
	
	
	#print(stateNames[currentState])
