# enemy.gd — Scene "Enemy" (CharacterBody2D + ColorRect)
# Musuh sederhana: bergerak acak per petak dan bisa mati oleh ledakan.
extends CharacterBody2D

const MOVE_DURATION := 0.5
const DIRECTIONS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var current_cell := Vector2i.ZERO
var _moving := false
var _move_progress := 0.0
var _move_from := Vector2.ZERO
var _move_to := Vector2.ZERO
var _think_timer := 0.0

func _ready() -> void:
	add_to_group("enemies")
	GameManager.register_enemy(self)
	position = Grid.grid_to_world(current_cell)

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	if _moving:
		_move_progress += delta / MOVE_DURATION
		var t := 1.0 - pow(1.0 - clampf(_move_progress, 0.0, 1.0), 2.0)  # ease-out quad
		if _move_progress >= 1.0:
			position = _move_to
			_moving = false
		else:
			position = _move_from.lerp(_move_to, t)
	else:
		_think_timer -= delta
		if _think_timer <= 0.0:
			_think_timer = randf_range(0.3, 1.2)
			var dir: Vector2i = DIRECTIONS.pick_random()
			var target := current_cell + dir
			if GameManager.is_walkable(target):
				current_cell = target
				_move_from = position
				_move_to = Grid.grid_to_world(current_cell)
				_moving = true
				_move_progress = 0.0

func take_damage() -> void:
	GameManager.unregister_enemy(self)
	visible = false
	set_process(false)
	queue_free()
