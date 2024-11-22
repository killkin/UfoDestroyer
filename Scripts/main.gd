extends Node2D

@onready var RestartWidget = preload("res://Scenes/user_inreface.tscn")
@onready var Character = $Character
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func endGame():
	var widget = RestartWidget.instantiate()
	widget.is_alone = true
	get_viewport().get_camera_2d().add_child(widget)
