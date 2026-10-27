# main.gd — Scene "Main" (Node2D)
# Level builder berbasis string grid + UI state (Menang/Kalah).
# Grid 15x13: '#' = HardWall, 'o' = SoftWall, '.' = lantai, 'P' = Player, 'E' = Enemy.
extends Node2D

const WALL_SCENE := preload("res://scenes/wall.tscn")
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

var level_data: Array[String] = [
	"###############",
	"#P.....#...o..#",
	"#.#o.#.#o#o#o.#",
	"#.............#",
	"#o#o#o##o##o#o#",
	"#............E#",
	"###.#.#.#.#.###",
	"#o..#...#..o.o#",
	"#.#o#o###o#o#.#",
	"#......E....o.#",
	"#o#o#.##o##.#o#",
	"#.....#..#....#",
	"###############",
]

@onready var walls_root: Node2D = $Walls
@onready var actors_root: Node2D = $Actors
@onready var fx_root: Node2D = $FX
@onready var result_label: Label = $UI/ResultLabel
@onready var restart_button: Button = $UI/RestartButton

func _ready() -> void:
	_build_level()
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.current_state = GameManager.GameState.PLAYING
	result_label.visible = false
	restart_button.visible = false

func _build_level() -> void:
	# Lantai dasar sebagai placeholder visual.
	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.25, 0.45, 0.25)
	floor_rect.offset_right = Grid.MAP_WIDTH * Grid.TILE_SIZE
	floor_rect.offset_bottom = Grid.MAP_HEIGHT * Grid.TILE_SIZE
	floor_rect.z_index = -10
	add_child(floor_rect)

	for y in level_data.size():
		var row := level_data[y]
		for x in row.length():
			var cell := Vector2i(x, y)
			match row[x]:
				"#":
					_spawn_wall(cell, WallSceneType.HARD)
				"o":
					_spawn_wall(cell, WallSceneType.SOFT)
				"P":
					_spawn_player(cell)
				"E":
					_spawn_enemy(cell)

enum WallSceneType { HARD, SOFT }

func _spawn_wall(cell: Vector2i, type: WallSceneType) -> void:
	var wall := WALL_SCENE.instantiate()
	wall.cell = cell
	wall.wall_type = WallSceneType.HARD if type == WallSceneType.HARD else WallSceneType.SOFT
	walls_root.add_child(wall)

func _spawn_player(cell: Vector2i) -> void:
	var player := PLAYER_SCENE.instantiate()
	player.current_cell = cell
	actors_root.add_child(player)

func _spawn_enemy(cell: Vector2i) -> void:
	var enemy := ENEMY_SCENE.instantiate()
	enemy.current_cell = cell
	actors_root.add_child(enemy)

func _on_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.WIN:
			_show_result("MENANG!\nTekan R atau tombol Restart")
		GameManager.GameState.LOSE:
			_show_result("GAME OVER\nTekan R atau tombol Restart")
		_:
			result_label.visible = false
			restart_button.visible = false

func _show_result(text: String) -> void:
	result_label.text = text
	result_label.visible = true
	restart_button.visible = true   # khusus pengguna sentuh (Android)

func _on_restart_pressed() -> void:
	GameManager.restart()
