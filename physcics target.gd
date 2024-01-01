extends RigidBody3D

var health = 35

# Called when the node enters the scene tree for the first time.
func hitSuccess(damage):
	health -= damage
	print("enemy health: " + str(health))
	if health <= 0:
		queue_free()
