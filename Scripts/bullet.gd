extends Node2D

@onready var ray = $RayCast2D
@onready var Gun = $Gun

func _ready():
	Gun.pitch_scale= randf_range(1,2)

func _on_life_timer_timeout():
	var body = ray.get_collider()
	if body and body.has_method("death"):
		body.death()
	
	queue_free()
