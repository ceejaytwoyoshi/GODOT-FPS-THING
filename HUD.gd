extends CanvasLayer

@onready var currentWeapon = $"VBoxContainer/HBoxContainer/Current Weapon"
@onready var currentAmmo = $"VBoxContainer/HBoxContainer2/Current Ammo"
@onready var weaponStack = $"VBoxContainer/HBoxContainer3/Weapon Stack"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_weapon_manager_update_ammo(Ammo):
	currentAmmo.set_text(str(Ammo[0] , " / " , str(Ammo[1])))

func _on_weapon_manager_weapon_changed(weaponName):
	currentWeapon.set_text(weaponName)

func _on_weapon_manager_update_weapon_inv(weaponInv):
	for i in weaponInv:
		weaponStack.text += "\n" + i
