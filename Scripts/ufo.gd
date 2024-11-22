extends CharacterBody2D

@onready var ray = $RayCast2D
var captureObject = null  # Объект, с которым пересекается рейкаст
var was_colliding = false  # Флаг, отслеживающий, было ли пересечение
@onready var Anim = $UfoAnimation
var Life: int = 0
@onready var Demage = $Demage
var isDead:bool = false
@onready var Explosion = preload("res://Scenes/Explosion.tscn")
@onready var Hit = preload("res://Scenes/Hit.tscn")
@onready var Stars = preload("res://Scenes/Stars.tscn")
@onready var RestartWidget = preload("res://Scenes/user_inreface.tscn")
var speed:float = 400
var gravity = 500             # Сила гравитации
var bounce_factor = -0.8      # Коэффициент отскока для реалистичного поведения
var target:Node
var flighFromHere: bool = false
@onready var CatchLight = $CatchLight
@onready var CatchLightTimer = $CatchLight/CatchLight_Timer
@onready var LiftSound = $UfoAnimation/LiftUp
@onready var FallSound = $UfoAnimation/Fall

signal killed(ufo: Node)
signal catched(ufo:Node)

func _ready():
	Anim.play("Idle")

func UFOCrash(delta):
	velocity.y += gravity * delta  # Применяем гравитацию

		# Пытаемся переместить объект и проверяем наличие столкновений
	var collision_info = move_and_collide(velocity * delta)
		
		# Если есть столкновение, выполняем отскок
	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal())  # Отражаем скорость относительно нормали
		velocity.x *= 0.4  # Уменьшаем горизонтальную скорость при отскоке
		velocity.y *= 0.4  # Уменьшаем вертикальную скорость при отскоке

#Проверка затянула ли тарелка объект
func CheckCatch() -> bool:
	if global_position.distance_to(target.global_position) < 15 and !isDead:
		if target.has_method("camDetach"):
			target.camDetach(self)

			var widget = RestartWidget.instantiate()
			widget.is_alone = false
			if get_tree().get_nodes_in_group("Interface").is_empty():
				get_node("Camera2D").add_child(widget)
			var _stars = Stars.instantiate()
			add_child(_stars)
		
		emit_signal("catched", self)
		target = null  # Обнуляем ссылку на объект
		return true
	else:
		return false

#Передвитжение к объекту
func MoveToObject(delta):
	if isDead or target==null:
		return
	
	var direction = (target.global_position - global_position).normalized()
	global_position.x += direction.x * speed * delta

func CatchLightAnim(on: bool):
	
	if on:
		if CatchLightTimer.is_stopped():
			CatchLight.visible = on
			CatchLightTimer.start(0.1)
	else:
		CatchLight.visible = on
		CatchLightTimer.stop
		
	
#Проверка луча
func CheckRay(delta):
	if ray.is_colliding() and not isDead:
			
		var new_capture_object = ray.get_collider()
		# Если есть пересечение и оно началось с новым объектом
		if new_capture_object==target and new_capture_object.has_method("fly"):
			captureObject = new_capture_object
			_liftSound(true)
			captureObject.velocity = Vector2.ZERO
			captureObject.fly(true)  # Активируем режим полёта
			was_colliding = true  # Устанавливаем флаг состояния пересечения		

		# Применяем подъёмную силу, если объект всё ещё пересекается с рейкастом
		if was_colliding and target:
			var power:float
			if target.name == "Character":
				power = 2400
			else:
				power = 700
			target.velocity.y -= power * delta
			CatchLightAnim(true)
			target.move_and_slide()
				
		else:
			# Если пересечения больше нет, отключаем режим полёта только один раз
			if was_colliding and target!=null:
				ReleaseObject()

func _liftSound(active:bool):
	if active:
		if not LiftSound.is_playing():
			LiftSound.play()
	else:
		LiftSound.stop()

#Обработка физики
func _physics_process(delta):
	
	if isDead:
		UFOCrash(delta)
		return
	
	if flighFromHere and !isDead:
		go_up()
	
	if target==null:
		return
	
	MoveToObject(delta)
	
	if !CheckCatch():
		CheckRay(delta)

#Отпускание объекта
func ReleaseObject():
	CatchLightAnim(false)
	_liftSound(false)
	if target!=null:
		target.fly(false)  # Отключаем режим полёта
		target.move_and_slide()
		target = null  # Сбрасываем объект
		was_colliding = false  # Сбрасываем флаг пересечения

func go_up():
	position.y = position.y-10
	if !is_visible_in_tree():
		queue_free()


#Смерть
func death():
	var HitInst = Hit.instantiate()
	HitInst.position = global_position
	get_tree().root.add_child(HitInst)
	if isDead:
		return
	
	if Life == 1:
		Anim.play("Death")
		emit_signal("killed", self)
		FallSound.play()
		ReleaseObject()
		isDead = true
		createDeathTimer()
		$PointLight2D.visible=false
		
		
	else:
		Life += 1
		Demage.visible = true
		$Demage/DamageParticles.emitting=true

func endLife():
	var _eplosioninst = Explosion.instantiate()
	_eplosioninst.position = global_position
	get_tree().root.add_child(_eplosioninst)
	queue_free()

#Конец игры

#Тарелка не нужна и улетает
func fly_away():
	flighFromHere = true
	CatchLightAnim(false)

func createDeathTimer():
	var DeathTimer = Timer.new()
	DeathTimer.wait_time = 2  # Устанавливаем время ожидания таймера
	DeathTimer.one_shot = true  # Одноразовый таймер
	DeathTimer.connect("timeout", Callable (self, "endLife"))  
	add_child(DeathTimer)  # Добавляем таймер как дочерний узел
	DeathTimer.start()  # Запускаем таймер


func _on_catch_light_timer_timeout():
	var new_opacity: float = randf_range(0.5,0.7)
	CatchLight.modulate = Color(modulate.r,modulate.g,modulate.b,new_opacity)
	CatchLightTimer.start(0.1)	
