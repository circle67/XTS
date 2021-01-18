extends KinematicBody2D

export (int) var health = 20
export (int) var maxHealth = 20

func stats():
	# Clamp health between the min and max
	health = clamp(health, 0, maxHealth)
	
	if health <= 0:
		queue_free()

func _process(_delta):
	stats()
