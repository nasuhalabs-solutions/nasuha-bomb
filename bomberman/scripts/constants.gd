# constants.gd — Autoload singleton "Grid": konstanta & konversi koordinat Grid <-> World.
extends Node2D

# Konstanta grid & konversi koordinat Grid <-> World (dipakai via "Grid.xxx").
const TILE_SIZE := 64
const MAP_WIDTH := 15       # jumlah kolom petak
const MAP_HEIGHT := 13      # jumlah baris petak

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos) * TILE_SIZE + Vector2(TILE_SIZE, TILE_SIZE) * 0.5

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / TILE_SIZE), floori(world_pos.y / TILE_SIZE))
