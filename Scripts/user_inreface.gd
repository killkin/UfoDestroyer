extends Control

@onready var Player = $RestartButton/AnimationPlayer
var is_alone: bool = false
func _ready():
	Player.play("Fade")
	$TextureRect.visible = is_alone

func _on_restart_button_pressed():
	$RestartButton.disabled = true
	get_tree().reload_current_scene()
