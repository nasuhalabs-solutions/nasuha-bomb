# game_manager.gd — Autoload singleton (GameManager)
# Mengelola state game (mulai/menang/kalah), level saat ini, dan referensi
# ke node-node penting di scene aktif (grid dinding, pemain, musuh).
extends Node

enum GameState { MENU, PLAYING, WIN, LOSE }

signal state_changed(new_state: GameState)

var current_state: GameState = GameState.MENU:
	set(value):
		current_state = value
		state_changed.emit(value)

var current_level: int = 1

# Referensi yang diisi oleh Main.tscn saat level dimuat.
var grid: Array = []              # Array[Array] berisi String tile ("#", "o", ".", "P", "E")
var wall_nodes: Dictionary = {}   # Vector2i -> Node (Wall)
var players: Array[Node2D] = []   # Semua instance Player aktif
var enemies: Array[Node2D] = []   # Semua instance Enemy aktif

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_game() -> void:
	current_level = 1
	load_level(current_level)

func load_level(_level: int) -> void:
	# Placeholder: Main.tscn memiliki data level sendiri.
	# Saat pindah level, cukup reload scene utama.
	get_tree().reload_current_scene()
	current_state = GameState.PLAYING

func on_player_died() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.LOSE
		print("GAME OVER — kalah!")

func on_enemies_defeated() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.WIN
		print("MENANG! Semua musuh hilang.")

func restart() -> void:
	# Reset state sebelum reload agar PLAYING bisa diset ulang oleh Main.
	current_state = GameState.MENU
	get_tree().reload_current_scene.call_deferred()

func is_playing() -> bool:
	return current_state == GameState.PLAYING

# ---- Utilitas grid ----
func is_walkable(cell: Vector2i) -> bool:
	if not _in_bounds(cell):
		return false
	return wall_nodes.get(cell) == null

func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < Grid.MAP_WIDTH and cell.y < Grid.MAP_HEIGHT

func register_wall(cell: Vector2i, node: Node) -> void:
	wall_nodes[cell] = node

func unregister_wall(node: Node) -> void:
	var keys := wall_nodes.keys()
	for k in keys:
		if wall_nodes[k] == node:
			wall_nodes.erase(k)

func register_player(p: Node2D) -> void:
	if not players.has(p):
		players.append(p)

func unregister_player(p: Node2D) -> void:
	players.erase(p)

func register_enemy(e: Node2D) -> void:
	if not enemies.has(e):
		enemies.append(e)

func unregister_enemy(e: Node2D) -> void:
	enemies.erase(e)
	if enemies.is_empty() and current_state == GameState.PLAYING:
		on_enemies_defeated()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_level") and current_state != GameState.PLAYING:
		restart()
