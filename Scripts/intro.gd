extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	$AnimationPlayer.play("ShowWork")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func next():
	$Cursor.position.x = get_viewport().size.x/2
