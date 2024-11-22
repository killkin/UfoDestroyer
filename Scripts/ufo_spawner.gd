extends Node2D

var UFO = preload("res://Scenes/UFO.tscn")  # Префаб UFO
var spawn_distance: float
var UFOcount: int = 0
var targets = {}  # Словарь
var RespawnTimeMax: int = 3
var RespawnTimeMin: int = 1
var SpawnTimer: Timer  # Таймер для респауна UFO
var game_over: bool = false  # Флаг завершения игры


# Создаем точки спавна
func CreateSpawnPoints():
	spawn_distance = get_viewport().get_size().x * 3

# Создаем таймер
func CreateSpawnTimer():
	SpawnTimer = Timer.new()
	add_child(SpawnTimer)
	SpawnTimer.connect("timeout", Callable(self, "spawnerTimeout"))
	StartTimer()

func spawnerTimeout():
	# Создаем UFO по окончанию таймера
	CreateUFO()

# Создаем список целей
func CollectTargets():
	for target in get_tree().get_nodes_in_group("target"):  # Группа "target" должна включать все объекты-цели
		targets[target] = null

func _ready():
	# Создаем точки спавна
	CreateSpawnPoints()
	# Создаем список целей
	CollectTargets()
	# Создаем таймер
	CreateSpawnTimer()

func CreateUFO():
	# Проверяем, что есть незахваченные цели перед созданием нового UFO
	var newtarget = get_random_uncaptured_target()
	
	if newtarget == null or game_over:
		SpawnTimer.stop()
		return

	#Создание тарелки и назначение цели
	var left: bool = randi_range(0, 1)
	var negative: int = -1 if left else 1
	var random_x = negative * spawn_distance
	var ufo = UFO.instantiate()
	ufo.position = Vector2(random_x, position.y - 350-randi_range(0,50))
	ufo.target = newtarget
	writeufoinlist(newtarget, ufo)
	add_child(ufo)

	# Подключение сигналов
	ufo.connect("killed", Callable(self, "_on_ufo_killed"))
	ufo.connect("catched", Callable(self, "_on_ufo_catched"))
	
func _on_ufo_killed(ufo: Node):
	reset_ufo_target(ufo)
	StartTimer()  # Перезапускаем таймер

#Поймал цель, хватай дальше или улетай
func _on_ufo_catched(ufo:Node):
	var target = targets.find_key(ufo)
	if target.name == "Character":
		stop_game(false)
	
	delete_target(target)
	RespawnTimeMax = clampi(RespawnTimeMax-1, 1,4)
	ufo.fly_away()  # Убедитесь, что у UFO есть метод fly_away
	

# Функция для записи UFO в список
func writeufoinlist(target: Node, ufo: Node):
	targets[target] = ufo

# Удалить цель из словаря
func delete_target(target: Node) -> void:
	if target == null:
		return
	target.queue_free()
	targets.erase(target)
	if targets.size() == 1:
		get_parent().endGame()
		for ufo in get_tree().get_nodes_in_group("ufo"):
			ufo.target = null
		stop_game(true)

# Сбросить цель UFO
func reset_ufo_target(ufo: Node) -> void:
	for key in targets.keys():
		if targets[key] == ufo:
			targets[key] = null
			return

# Получить случайную незахваченную цель
func get_random_uncaptured_target() -> Node:
	var uncaptured_targets = []  # Список для незахваченных целей
	for key in targets.keys():  # Итерируем по ключам
		if targets[key] == null:  # Если цель ещё не захвачена
			uncaptured_targets.append(key)  # Добавляем ключ в список

	if uncaptured_targets.size() > 0:  # Если есть незахваченные цели
		var random_target = uncaptured_targets[randi() % uncaptured_targets.size()]  # Выбираем случайную цель
		return random_target  # Возвращаем случайную цель
	else:
		return null  # Если все цели захвачены, возвращаем null

func StartTimer():
	if not game_over:
		SpawnTimer.start(randf_range(RespawnTimeMin, RespawnTimeMax))

# Конец Игры
func stop_game(characterIsKilled:bool):
	game_over = true
	SpawnTimer.stop()
	if characterIsKilled:
		get_parent().endGame()
