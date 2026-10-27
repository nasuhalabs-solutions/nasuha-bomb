# bomb.gd — Scene "Bomb" (Area2D + ColorRect + CollisionShape2D)
# Mengelola timer countdown, lalu memicu Explosion berbentuk salib.
extends Area2D

signal exploded

@export var fuse_time := 2.0        # detik sebelum meledak
@export var blast_range := 1        # jangkauan ledakan (jumlah petak ke tiap arah)

var owner_player: Node = null       # siapa yang menaruh bom ini
var cell := Vector2i.ZERO           # posisi grid bom (diisi Player)

@onready var visual: ColorRect = $ColorRect

func _ready() -> void:
	add_to_group("bombs")
	# Bom tidak menghalangi pergerakan, tapi tetap bisa dideteksi fisik bila perlu.
	collision_layer = 0
	collision_mask = 0
	$Timer.wait_time = fuse_time
	$Timer.timeout.connect(_explode)
	$Timer.start()

func _process(_delta: float) -> void:
	# Efek berkedip sederhana sebagai placeholder "timer".
	var blink := fmod(Time.get_ticks_msec() / 1000.0, 0.3) < 0.15
	visual.color = Color(0.1, 0.1, 0.1) if blink else Color(0.9, 0.2, 0.2)

func _explode() -> void:
	exploded.emit()
	# Anti-reentry: bom hanya boleh meledak sekali (chain reaction bisa memicu ganda).
	set_process(false)
	$Timer.stop()
	var explosion_scene := load("res://scenes/explosion.tscn")
	var cells := _compute_cross_cells()
	for c in cells:
		var fx := explosion_scene.instantiate()
		get_tree().current_scene.get_node("FX").add_child(fx)
		fx.cell = c
		fx.global_position = Grid.grid_to_world(c)
	# Hancurkan bom tetangga yang berada di sel api (chain reaction).
	for b in get_tree().get_nodes_in_group("bombs"):
		if b != self and b.cell in cells:
			b.get_node("Timer").stop()
			b._explode.call_deferred()
	queue_free()

func _compute_cross_cells() -> Array[Vector2i]:
	# Hasilkan sel berbentuk salib: pusat + rentang ke 4 arah.
	# Ledakan dihentikan oleh HardWall; SoftWall ikut hancur tapi tetap terbakar.
	var cells: Array[Vector2i] = [cell]
	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for d in directions:
		for i in range(1, blast_range + 1):
			var c := cell + d * i
			cells.append(c)
			var wall: Node = GameManager.wall_nodes.get(c)
			if wall != null and "wall_type" in wall and wall.wall_type == 0:
				cells.pop_back()  # HardWall memblokir, api tidak sampai ke selnya
				break
	return cells
