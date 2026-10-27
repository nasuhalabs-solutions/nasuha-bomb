# explosion.gd — Scene "Explosion" (Area2D + ColorRect + CollisionShape2D + Timer)
# Satu instance = satu petak api dari lengan salib ledakan.
# Bertanggung jawab atas DETEKSI TUMBUKAN ledakan:
#  - Player  -> take_damage()
#  - Enemy   -> take_damage()
#  - SoftWall-> hancur (take_explosion())
#  - Bomb lain -> chain reaction (ikut meledak lebih cepat)
extends Area2D

var cell := Vector2i.ZERO
var _hit_this_frame := false

@onready var visual: ColorRect = $ColorRect

func _ready() -> void:
	collision_layer = 16   # bit 5 = layer "Explosions"
	collision_mask = 2 | 4 | 8  # Player(2) | Enemies(4) | SoftWalls(8)
	monitoring = true
	monitorable = false
	area_shape_setup()
	body_entered.connect(_on_body_entered)
	$Timer.wait_time = 0.5  # umur api
	$Timer.one_shot = true
	$Timer.timeout.connect(queue_free)
	$Timer.start()

func area_shape_setup() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(Grid.TILE_SIZE, Grid.TILE_SIZE) * 0.9
	shape.shape = rect
	add_child(shape)

func _physics_process(_delta: float) -> void:
	# Selain deteksi sinyal body_entered, cek juga posisi grid secara logis.
	# Ini menangkap entitas yang sedang "melintas" di sel ini meski shape-nya kecil.
	if _hit_this_frame:
		return
	for p in GameManager.players:
		if is_instance_valid(p) and p.current_cell == cell:
			_hit_this_frame = true
			p.take_damage()
			break
	for e in GameManager.enemies:
		if is_instance_valid(e) and "current_cell" in e and e.current_cell == cell:
			_hit_this_frame = true
			e.take_damage()
			break
	var wall: Node = GameManager.wall_nodes.get(cell)
	if wall != null and "wall_type" in wall and wall.wall_type == wall.WallType.SOFT:
		GameManager.unregister_wall(wall)
		wall.take_explosion()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage()
	elif body.is_in_group("enemies"):
		body.take_damage()
	elif body.has_method("take_explosion"):
		body.take_explosion()
