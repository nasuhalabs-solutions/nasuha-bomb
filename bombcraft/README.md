# BombCraft: Single Source of Blast — Godot 4.x (GDScript, target Android)

Fondasi boilerplate yang **bisa langsung dijalankan** (placeholder grafis berupa `ColorRect`,
tanpa aset/animasi). Dibuka dengan **Godot 4.2+** → *Import* → pilih `project.godot`.

## Kontrol
| Aksi | Keyboard (testing / Samsung DeX) | Android (sentuh) |
|---|---|---|
| Gerak 1 petak | `WASD` / tombol panah | Swipe ke arah (lengan virtual) |
| Taruh bom | `Spasi` | Ketuk layar |
| Ulang (saat menang/kalah) | `R` | Tombol "Restart" di UI |

## Struktur Proyek
```
res://
├── project.godot            # autoload, input map, physics layers, rendering mobile
├── scenes/
│   ├── main.tscn            # scene utama (level builder + UI state)
│   ├── player.tscn          # CharacterBody2D + ColorRect + CollisionShape2D
│   ├── bomb.tscn            # Area2D + ColorRect + CollisionShape2D + Timer
│   ├── explosion.tscn       # Area2D + ColorRect + Timer
│   ├── wall.tscn            # Node2D + ColorRect + StaticBody2D + CollisionShape2D
│   └── enemy.tscn           # CharacterBody2D + ColorRect + CollisionShape2D
└── scripts/
    ├── game_manager.gd      # Autoload "GameManager": state machine & registry level
    ├── constants.gd         # Autoload "Grid": TILE_SIZE, ukuran peta, grid<->world
    ├── main.gd              # Membangun level dari string grid + UI menang/kalah
    ├── player.gd            # Input, pergerakan grid, penempatan bom
    ├── bomb.gd              # Fuse timer 2 detik, hitung sel salib ledakan
    ├── explosion.gd         # Deteksi tabrakan: Player, Enemy, SoftWall
    ├── wall.gd              # HardWall / SoftWall (enum WallType)
    └── enemy.gd             # Musuh placeholder (jalan acak per petak)
```

## Scene Tree `main.tscn`
```
Main (Node2D, main.gd)
├── Camera2D                       # dipusatkan ke tengah peta 15x13 @64px
├── Walls (Node2D)                 # induk semua instance wall.tscn
├── Actors (Node2D)                # induk Player & Enemy
├── FX (Node2D)                    # induk Bomb & Explosion (agar tidak ikut bebas saat entitas mati)
└── UI (CanvasLayer)
    ├── ResultLabel (Label)        # teks MENANG / GAME OVER
    └── RestartButton (Button)     # khusus sentuh Android
```

### Scene terpisah
- **player.tscn**: `Player` (CharacterBody2D, group `player`, layer 2) → `ColorRect` (kuning), `CollisionShape2D`.
- **bomb.tscn**: `Bomb` (Area2D, layer/mask 0) → `ColorRect` (berkedip), `CollisionShape2D`, `Timer` (fuse 2 dtk).
- **explosion.tscn**: `Explosion` (Area2D, layer 16, mask 2|4|8) → `ColorRect` (oranye), `Timer` (umur api 0.5 dtk). Satu instance = satu petak api.
- **wall.tscn**: `Wall` (Node2D) → `ColorRect`, `StaticBody2D` + `CollisionShape2D`. Properti `wall_type` menentukan HARD (abu-abu, layer 1) / SOFT (cokelat, layer 8, group `soft_walls`).
- **enemy.tscn**: `Enemy` (CharacterBody2D, group `enemies`, layer 4) → `ColorRect` (ungu), `CollisionShape2D`.

## Arsitektur & Keputusan Desain
1. **Grid-based movement tanpa raycast fisik.** Setiap Wall mendaftarkan dirinya ke
   `GameManager.wall_nodes` (Dictionary `Vector2i -> Node`). Pergerakan cukup cek
   `GameManager.is_walkable(cell)` — deterministik dan murah untuk mobile. Posisi visual
   pemain di-*lerp* antar petak (`MOVE_DURATION`) agar tetap halus meski logikanya per-tile.
2. **State machine terpusat** di autoload `GameManager`: `MENU → PLAYING → WIN/LOSE`,
   diekspos lewat signal `state_changed` yang didengar `main.gd` untuk menampilkan UI.
   Kemenangan dipicu otomatis saat `enemies` kosong; kekalahan saat pemain kena ledakan.
3. **Ledakan salib** dihitung secara logis di `bomb.gd::_compute_cross_cells()`
   (pusat + `blast_range` ke 4 arah, dihentikan HardWall), lalu satu `explosion.tscn`
   di-spawn per sel. `explosion.gd` mendeteksi korban via **dua jalur**: sinyal
   `body_entered` (fisik) dan pencocokan `current_cell` per frame (logis) — menjamin
   SoftWall yang berdiri di atas sel api ikut hancur.
4. **Input ganda:** keyboard via `InputMap` actions (`event.is_action_pressed`) untuk
   testing desktop/DeX; `InputEventScreenTouch` untuk Android (tap = bom, swipe = gerak)
   plus `TouchScreenButton` virtual sebagai cadangan.
5. **Rendering mobile:** `gl_compatibility` renderer + `canvas_items` stretch mode
   (diatur di `project.godot`).

## Physics Layers
| Layer | Bit | Nama | Dipakai oleh |
|---|---|---|---|
| 1 | 1  | Walls      | HardWall (StaticBody2D) |
| 2 | 2  | Player     | Player |
| 3 | 4  | Enemies    | Enemy |
| 4 | 8  | SoftWalls  | SoftWall (bisa dideteksi ledakan) |
| 5 | 16 | Explosions | Explosion (Area2D) |

## Cara Menambah Level
Edit `level_data` di `scripts/main.gd` (grid string 15×13):
`#` HardWall · `o` SoftWall · `.` lantai · `P` titik muncul pemain · `E` musuh.

## Roadmap Pengembangan Lanjutan
- Ganti `ColorRect` dengan `Sprite2D`/`AnimatedSprite2D` + `TileMapLayer` untuk peta.
- Power-up (bom tambahan, api lebih panjang, speed) setelah SoftWall hancur.
- AI musuh yang mengejar pemain, animasi ledakan, audio, dan save progress.
- Export Android: *Project → Export → Android* (butuh debug keystore + SDK Godot 4).
