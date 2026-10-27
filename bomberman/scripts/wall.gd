# wall.gd — Scene "Wall" (Node2D + ColorRect + StaticBody2D + CollisionShape2D)
# Digunakan untuk HardWall (tidak bisa dihancurkan) dan SoftWall (bisa dihancurkan).
#
# Prinsip kerja grid-based: tumbukan fisik TIDAK menghentikan pergerakan.
# Wall hanya mendaftarkan dirinya ke GameManager sebagai sel yang "tidak walkable",
# dan menggambar diri di posisi grid-nya masing-masing.
extends Node2D

enum WallType { HARD, SOFT }

@export var wall_type: WallType = WallType.HARD
@export var cell: Vector2i = Vector2i.ZERO  # posisi di grid, diisi oleh level builder

@onready var visual: ColorRect = $ColorRect
@onready var body: StaticBody2D = $StaticBody2D

func _ready() -> void:
	position = Grid.grid_to_world(cell) - Vector2(Grid.TILE_SIZE, Grid.TILE_SIZE) * 0.5
	_apply_visuals()
	GameManager.register_wall(cell, self)
	if wall_type == WallType.SOFT:
		body.add_to_group("soft_walls")

func _apply_visuals() -> void:
	match wall_type:
		WallType.HARD:
			visual.color = Color(0.3, 0.3, 0.35)     # abu-abu gelap
		WallType.SOFT:
			visual.color = Color(0.75, 0.55, 0.3)    # cokelat bata
	if body:
		body.collision_layer = 1 if wall_type == WallType.HARD else 8
		# layer 1 = Walls (hard), layer 4 (bit ke-3) = SoftWalls

# Dipanggil oleh Explosion ketika terkena ledakan.
func take_explosion() -> void:
	if wall_type == WallType.SOFT:
		GameManager.unregister_wall(self)
		queue_free()
