extends CharacterBody2D

@export var speed: float = 500  # Скорость движения персонажа
@export var gravity: float = 500.0  # Сила гравитации
@onready var Anim = $Animation
@onready var ShootTimer = $ShootTimer
@onready var Bullet = preload("res://Scenes/Bullet.tscn")
@onready var _camera = $Camera2D
@onready var intro = $Camera2D/Intro

var min_x: float = -300
var max_x: float = 1300 
var initial_y: float


var particlesTimer
var CanShoot: bool = true
var Shooting: bool = false

enum AnimState {
	Run,
	Idle,
	Fall,
	Fire,
	Catched
}

var playerState = AnimState.Idle

var offset_position:float
var target_position:Vector2
var is_moving: bool = false  # Флаг, указывающий, движется ли персонаж
var is_flying: bool = false  # Флаг, указывающий, летит, ли персонаж
# Функция для установки анимации
func set_animation_state(state: AnimState) -> void:
	if playerState != state:
		playerState = state
		match state:
			AnimState.Run:
				Anim.play("Run")
				Anim.speed_scale = 2.0
			AnimState.Idle:
				Anim.play("Idle")
				Anim.speed_scale = 1.0
			AnimState.Fall:
				Anim.play("Fall")
				Anim.speed_scale = 1.0
			AnimState.Fire:
				Anim.play("Fire")
				Anim.speed_scale = 1.0
				CanShoot = false
				Shooting = true
				ShootTimer.start(0.8)  # Старт таймера для стрельбы
			AnimState.Catched:
				Anim.play("Fall")
				Anim.speed_scale = 1.0
				pass

func _ready():
	# Сохраняем начальную позицию по Y
	initial_y = _camera.global_position.y

# Инпут
func _unhandled_input(event):
	if playerState==AnimState.Fire:
		return
	if event is InputEventMouseButton and event.pressed:
		# Получаем мировые координаты при клике мыши
		target_position = get_global_mouse_position()
		is_moving = true
		if is_instance_valid(intro):
			intro.next()
	elif event is InputEventScreenTouch and event.pressed:
		# Получаем мировые координаты при касании экрана
		target_position = get_viewport().get_camera_2d().unproject_position(event.position)
		is_moving = true
		if is_instance_valid(intro):
			intro.next

# Стрельба - клик по персонажу
func _on_input_event(_viewport, event, _shape_idx):
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed and playerState != AnimState.Fire:
		if CanShoot and !Shooting:
			if is_instance_valid(intro):
				intro.queue_free()
			set_animation_state(AnimState.Fire)
			is_moving = false
			velocity.x = 0
			Shooting = true
			particlesTimer = Timer.new()
			add_child(particlesTimer)
			particlesTimer.connect("timeout",Callable( self, "_on_timer_timeout"))
			particlesTimer.start()

# Таймер для завершения стрельбы

func _on_shoot_timer_timeout():
	spawnBullet()
	CanShoot = true
	Shooting = false  # Разрешаем стрелять снова
	ShootTimer.stop()  # Останавливаем таймер

	# После того как выстрел завершен, возвращаем предыдущее значение
	if !is_on_floor():
		set_animation_state(AnimState.Fall)
	elif is_moving:
		set_animation_state(AnimState.Run)
	else:
		set_animation_state(AnimState.Idle)

func Run() -> void:
	if !is_moving or Shooting or is_flying:
		return
	# Игнорируем движение, если активна анимация стрельбы или если персонаж не летит или персонаж не на полу и не двигается, выходим из функции
	if !is_on_floor():
		return

	# Если персонаж близко к целевой позиции, останавливаем движение
	if abs(global_position.x - target_position.x) < 15:
		is_moving = false
		velocity.x = 0
		set_animation_state(AnimState.Idle)
		return
	
	else:
		# Определяем направление и устанавливаем скорость
		var direction = sign(target_position.x - position.x)
		velocity.x = direction * speed
		set_animation_state(AnimState.Run)
		Anim.flip_h = direction < 0

func Falling(delta: float):
	if !is_on_floor() and !is_flying:
		velocity.y += gravity * delta
		if !Shooting:
			set_animation_state(AnimState.Fall)
	else:
		velocity.y = 0
		if !Shooting and !is_moving:
			set_animation_state(AnimState.Idle)

func _physics_process(delta: float) -> void:
	# Гравитация персонажа
	Falling(delta) 
	# Движение персонажа
	Run()
	# Перемещаем персонажа с учетом гравитации и столкновений
	move_and_slide()
	clampCamera()

func clampCamera():
	position.x = clamp(position.x, min_x, max_x)
	_camera.global_position.y = initial_y
	if position.x == min_x or position.x == max_x:
		is_moving = false

# Функция для создания пули
func spawnBullet():
	var _bullet = Bullet.instantiate()
	_bullet.position = %BulletMuzzle.global_position
	get_tree().root.add_child(_bullet)

func _on_timer_timeout():
	if particlesTimer != null:
		particlesTimer.queue_free()  # Удаляем таймер из сцены

func fly(flying:bool):
	is_flying = flying

func camDetach(ufo:Node):
	if ufo:
		var Pos = _camera.global_position
		remove_child(_camera)
		ufo.add_child(_camera)
		_camera.global_position = Pos
