extends Area2D

export (int) var speed = 750

var damage = 2

func _physics_process(delta):
	position += transform.x * speed * delta

func _on_Area2D_body_entered(body):
	if body.is_in_group("Enemies"):
		body.health -= damage
	queue_free()
