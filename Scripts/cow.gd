extends CharacterBody2D

var is_flying: bool = false
var is_running: bool = false
var is_walking: bool = false
var gravity = 500
var minX: float = -300
var maxX: float = 1300 
var runawayTarget: float
var runawayCount: int = 0
var walkTarget: float
var walkingTimer: Timer
var RunTimer:Timer

@onready var Anim = $AnimatedSprite2D

func _ready():
	var startTimer = Timer.new()
	startTimer.one_shot = true
	add_child(startTimer)
	startTimer.connect("timeout", Callable(self, "wait"))
	startTimer.start(1.0)
	Anim.flip_h = randi_range(0,1) == 0

func fly(flying: bool):
	is_flying = flying
	if flying:
		Anim.play("Run")
		Anim.speed_scale = 2
		if is_instance_valid(walkingTimer):
			walkingTimer.queue_free()
			is_walking =false
	else:
		RunAway()

func _physics_process(delta):
	Walking()
	Falling(delta)
	Run()
	move_and_slide()
	

# Спокойное поведение
func wait():
	StopAnyMove()
	Anim.speed_scale = 1
	Anim.play("StartEat")
	var eatTimer = Timer.new()
	eatTimer.one_shot = true
	add_child(eatTimer)
	eatTimer.connect("timeout", Callable(self, "eating"))
	eatTimer.start(0.3)
	eatTimer.connect("timeout", eatTimer.queue_free)

func eating():
	StopAnyMove()
	Anim.play("Eat")
	walkingTimer = Timer.new()
	walkingTimer.one_shot = true
	add_child(walkingTimer)
	walkingTimer.connect("timeout", Callable(self, "goWalk"))
	walkingTimer.start(randf_range(2, 5))
	walkingTimer.connect("timeout", walkingTimer.queue_free)

# Бег
func Run():
	if !is_on_floor() or is_flying or !is_running:
		return
	if abs(position.x - runawayTarget)<15:
		RunningEnd()
	var direction = sign(runawayTarget - position.x)
	velocity.x = direction * 200
	Anim.play("Run")
	Anim.speed_scale = 2
	Anim.flip_h = direction < 0

func Falling(delta):
	if !is_flying and !is_on_floor():
		velocity.y += gravity * delta
	elif is_on_floor():
		velocity.y = 0


func RunAway():
	RunTimer = Timer.new()
	RunTimer.one_shot = true
	add_child(RunTimer)
	RunTimer.connect("timeout", Callable(self, "RunningEnd"))
	RunTimer.start(2)
	RunTimer.connect("timeout", RunTimer.queue_free)
	Anim.play("Run")
	runawayTarget = randf_range(minX, maxX)
	is_running = true
	

func RunningEnd():
	if runawayCount >= 2:
		wait()
		
	else:
		RunAway()
		runawayCount += 1

func goWalk():
	walkTarget = randf_range(minX, maxX)
	is_walking = true
	Anim.play("Run")

func Walking():
	if !is_on_floor() or is_flying or is_running or !is_walking:
		return
	if abs(position.x - walkTarget) < 15:
		is_walking = false
		velocity.x = 0
		wait()
		return

	var direction = sign(walkTarget - position.x)
	velocity.x = direction * 50
	Anim.speed_scale = 1	
	Anim.flip_h = direction < 0

func StopAnyMove():
	velocity.x = 0
	runawayCount = 0
	Anim.speed_scale = 1
	if is_instance_valid(walkingTimer):
		walkingTimer.queue_free
	is_walking = false
	if is_instance_valid(RunTimer):
		RunTimer.queue_free()
	is_running = false
