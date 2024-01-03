extends Node3D
class_name CameraShake

var trauma = 0.0
@export var traumaRRate = 2.5

@export var maxX = 10.0
@export var maxY = 10.0
@export var maxZ = 5.0

var time = 0.0
@export var noise = FastNoiseLite.new()
@export var noiseSpeed = 50.0 

@onready var initialRotation = self.rotation_degrees

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	time += delta
	trauma = max(trauma - delta * traumaRRate, 0.0)
	
	self.rotation_degrees.x = initialRotation.x + maxX * get_shake_intensity() * get_noise_from_seed(0)
	self.rotation_degrees.y = initialRotation.y + maxY * get_shake_intensity() * get_noise_from_seed(1)
	self.rotation_degrees.z = initialRotation.z + maxZ * get_shake_intensity() * get_noise_from_seed(2)
	
	if self.rotation_degrees.y < 0:
		self.rotation_degrees.y = -self.rotation_degrees.y
	
	print(self.rotation_degrees.x, " , ", self.rotation_degrees.y, " , ", self.rotation_degrees.z)

func add_trauma(trauma_amount: float):
	trauma = clamp(trauma + trauma_amount, 0.0, 1.0)

func get_shake_intensity() -> float:
	return trauma * trauma

func get_noise_from_seed(_seed: int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(time * noiseSpeed)
