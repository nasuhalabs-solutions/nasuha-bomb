# player.gd — Scene "Player" (CharacterBody2D + ColorRect + CollisionShape2D)
# Mengelola input (keyboard untuk testing DeX, sentuh/swipe untuk Android),
# pergerakan grid-based per petak, dan penempatan bom.
extends CharacterBody2D

signal died

const MOVE_DURATION := 0.14        # detik untuk berpindah 1 petak
const BOMB_SCENE := preload("res://scenes/bomb.tscn")
const MAX_BOMBS := 2
const SWIPE_THRESHOLD := 40.0      # px minimum gestur swipe di layar sentuh

var current_cell := Vector2i.ZERO   # posisi logis di grid
var _moving := false
var _move_progress := 0.0
var _move_from := Vector2.ZERO
var _move_to := Vector2.ZERO
var _active_bombs: Array[Node] = []
var _touch_start := Vector2.INF     # awal sentuhan utk deteksi swipe vs tap
var _touch_moved := false           # true bila sentuhan sudah jadi swipe

@onready var visual: ColorRect = $ColorRect

func _ready() -> void:
	GameManager.register_player(self)
	position = Grid.grid_to_world(current_cell)

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_playing():
		return
	# --- Keyboard (testing desktop / Samsung DeX) ---
	var dir := Vector2i.ZERO
	if event.is_action_pressed("move_up"):
		dir = Vector2i.UP
	elif event.is_action_pressed("move_down"):
		dir = Vector2i.DOWN
	elif event.is_action_pressed("move_left"):
		dir = Vector2i.LEFT
	elif event.is_action_pressed("move_right"):
		dir = Vector2i.RIGHT
	if dir != Vector2i.ZERO:
		try_move(dir)
		return
	if event.is_action_pressed("place_bomb"):
		_place_bomb()
		return
	# --- Sentuh (Android): swipe = gerak, tap = taruh bom ---
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_touch_moved = false
		elif not _touch_moved:
			_place_bomb()   # ketukan singkat tanpa digeser => bom
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		# Satu gerakan per sentuhan: begitu melewati ambang, arah dikunci.
		if _touch_start != Vector2.INF and not _touch_moved:
			var delta := event.screen_position - _touch_start
			if delta.length() >= SWIPE_THRESHOLD:
				_touch_moved = true
				if absf(delta.x) > absf(delta.y):
					try_move(Vector2i.RIGHT if delta.x > 0 else Vector2i.LEFT)
				else:
					try_move(Vector2i.DOWN if delta.y > 0 else Vector2i.UP)

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	# Animasi geser antar-petak (tetap grid-based, hanya visual yang halus).
	if _moving:
		_move_progress += delta / MOVE_DURATION
		if _move_progress >= 1.0:
			position = _move_to
			_moving = false
		else:
			position = _move_from.lerp(_move_to, _move_progress)

func try_move(dir: Vector2i) -> void:
	if _moving:
		return
	var target := current_cell + dir
	if not GameManager.is_walkable(target):
		return
	current_cell = target
	_move_from = position
	_move_to = Grid.grid_to_world(current_cell)
	_moving = true
	_move_progress = 0.0

func _place_bomb() -> void:
	# Bersihkan referensi bom yang sudah hancur.
	_active_bombs = _active_bombs.filter(func(b): return is_instance_valid(b))
	if _active_bombs.size() >= MAX_BOMBS:
		return
	var bomb := BOMB_SCENE.instantiate()
	bomb.owner_player = self
	bomb.cell = current_cell
	get_tree().current_scene.get_node("FX").add_child(bomb)
	bomb.global_position = Grid.grid_to_world(current_cell)
	_active_bombs.append(bomb)
	bomb.exploded.connect(_on_bomb_exploded.bind(bomb))

func _on_bomb_exploded(bomb: Node) -> void:
	_active_bombs.erase(bomb)

# Dipanggil oleh Explosion saat pemain terkena ledakan.
func take_damage() -> void:
	if not GameManager.is_playing():
		return
	GameManager.unregister_player(self)
	died.emit()
	visible = false
	set_process(false)
	set_physics_process(false)
	GameManager.on_player_died()
	queue_free()
