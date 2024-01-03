extends Resource

class_name WeaponResource

@export var weaponName: String
@export var equipAnim: String
@export var shootAnim: String
@export var reloadAnim: String
@export var unequipAnim: String
@export var OOAAnim: String

@export var currentAmmo: int
@export var reserveAmmo: int
@export var magSize: int
@export var maxAmmo: int

@export var weaponSpread: float

@export var autoFire: bool

@export_flags("Hitscan", "Projectile") var attackType
@export var weaponRange: int
@export var damage: int


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
