extends Node3D

signal weaponChanged
signal updateAmmo
signal updateWeaponInv

@onready var Animation_Player = get_node("Hands/AnimationPlayer")

var currentWeapon = null

var weaponInv = []

var weaponIndicator = 0

var nextWeapon: String

var weaponList = {}

var debugBullet = preload("res://weapon resources/bullet_debug.tscn")

var shotCount = 0

@export var _weapon_resources: Array[WeaponResource]

@export var startWeapons: Array[String]
@onready var bulletPoint = $Hands/BulletPoint
@onready var spreadTimer = $SpreadTimer

enum {NULL, HITSCAN, PROJECTILE}

@export var camera_shake: CameraShake

# Called when the node enters the scene tree for the first time.
func _ready():
	initialize(startWeapons)
	randomize()

func _input(event):
	if event.is_action_pressed("weapon_up"):
		weaponIndicator = min(weaponIndicator+1, weaponInv.size()-1)
		exit(weaponInv[weaponIndicator])
	
	if event.is_action_pressed("weapon_down"):
		weaponIndicator = max(weaponIndicator-1, 0)
		exit(weaponInv[weaponIndicator])
	
	if event.is_action_pressed("shoot") and !Animation_Player.is_playing():
		shoot()
	
	if event.is_action_pressed("reload"):
		reload()

func initialize(_start_weapons: Array):
	for weapon in _weapon_resources:
		weaponList[weapon.weaponName] = weapon
	
	for i in _start_weapons:
		weaponInv.push_back(i)
	
	currentWeapon = weaponList[weaponInv[0]]
	emit_signal("updateWeaponInv", weaponInv)
	enter()

func enter():
	Animation_Player.queue(currentWeapon.equipAnim)
	emit_signal("weaponChanged", currentWeapon.weaponName)
	emit_signal("updateAmmo", [currentWeapon.currentAmmo, currentWeapon.reserveAmmo])

func exit(_next_weapon: String):
	if _next_weapon != currentWeapon.weaponName:
		if Animation_Player.get_current_animation() != currentWeapon.unequipAnim:
				Animation_Player.play(currentWeapon.unequipAnim)
				nextWeapon = _next_weapon

func weaponChange(weaponName: String):
	currentWeapon = weaponList[weaponName]
	nextWeapon = ""
	enter()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == currentWeapon.unequipAnim:
		weaponChange(nextWeapon)
	
	if anim_name == currentWeapon.shootAnim and currentWeapon.autoFire == true:
		if Input.is_action_pressed("shoot"):
			shoot()

func shoot():
	if currentWeapon.currentAmmo != 0 and !Animation_Player.is_playing():
		spreadTimer.start()
		camera_shake.add_trauma(1.0)
		#if !spreadTimer.is_stopped():
			#print("spread timer active")
		
		shotCount +=1
		print("Shot Count: " + str(shotCount))
		Animation_Player.play(currentWeapon.shootAnim)
		currentWeapon.currentAmmo -= 1
		emit_signal("updateAmmo", [currentWeapon.currentAmmo, currentWeapon.reserveAmmo])
		var cameraCollision = get_camera_collision()
		match currentWeapon.attackType:
			NULL:
				print("attack type not found")
			HITSCAN:
				hitscanCol(cameraCollision)
			PROJECTILE:
				pass
	else:
		reload()

func reload():
	if currentWeapon.currentAmmo == currentWeapon.magSize:
		return
	elif !Animation_Player.is_playing():
		if currentWeapon.reserveAmmo != 0:
			Animation_Player.play(currentWeapon.reloadAnim)
			var reloadAmount = min(currentWeapon.magSize - currentWeapon.currentAmmo, currentWeapon.magSize, currentWeapon.reserveAmmo)
			
			currentWeapon.currentAmmo += reloadAmount
			currentWeapon.reserveAmmo -= reloadAmount
			emit_signal("updateAmmo", [currentWeapon.currentAmmo, currentWeapon.reserveAmmo])
		else:
			Animation_Player.play(currentWeapon.OOAAnim)


func get_camera_collision()->Vector3:
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	var rayOrigin = camera.project_ray_origin(viewport/2)
	var rayEnd = rayOrigin + camera.project_ray_normal(viewport/2) * currentWeapon.weaponRange
	
	if shotCount > 1 and !spreadTimer.is_stopped():
		#print("Spread Active")
		rayEnd.x = rayEnd.x + randf_range(currentWeapon.weaponSpread, -currentWeapon.weaponSpread)
		rayEnd.y = rayEnd.y + randf_range(currentWeapon.weaponSpread, -currentWeapon.weaponSpread)
	else:
		rayEnd = rayOrigin + camera.project_ray_normal(viewport/2) * currentWeapon.weaponRange
	
	print(rayEnd.x, " ", rayEnd.y)
	
	var newIntersection = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd)
	var intersection = get_world_3d().direct_space_state.intersect_ray(newIntersection)
	
	if not intersection.is_empty():
		var colPoint = intersection.position
		return colPoint
	else:
		return rayEnd
	
func hitscanCol(colPoint):
	var bulletDir = (colPoint - bulletPoint.get_global_transform().origin).normalized()
	var newIntersection = PhysicsRayQueryParameters3D.create(bulletPoint.get_global_transform().origin, colPoint+bulletDir * 2)
	
	var bulletCol = get_world_3d().direct_space_state.intersect_ray(newIntersection)
	
	if bulletCol:
		var hitInidicator = debugBullet.instantiate()
		var world = get_tree().get_root()
		world.add_child(hitInidicator)
		
		hitInidicator.global_translate(bulletCol.position)
		
		hitscanDamage(bulletCol.collider)

func hitscanDamage(col):
	if col.is_in_group("target") and col.has_method("hitSuccess"):
		col.hitSuccess(currentWeapon.damage)
		print("IT'S WORKING?!?!")


func _on_spread_timer_timeout():
	shotCount = 0
	#print("spread timer stop")
