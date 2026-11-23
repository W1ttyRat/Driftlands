# Driftlands prototype plan

## Primary goal
Press play and stand on a small island: walk around, swing a sword toward the mouse to hit a skeleton dummy, and chop trees and mine rocks, with Wood and Stone counters going up. Nothing else.

## Decisions (from interview)
- GDScript, Godot 4.7.2 mono (`C:\Users\poisi\OneDrive\Desktop\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe`).
- Island = TileMapLayer + TileSet. Trees and rocks = scene tiles in a TileSetScenesCollectionSource.
- Controls: WASD move, left click swings toward the mouse, snapped to 4 directions (the art has 4 directions only).
- Skeleton: passive dummy, no AI, cannot hurt the player. 3 hits to die, no respawn. Trees and rocks: 3 hits each.
- HUD: two counters, `Wood: N`, `Stone: N`.
- Git repo in this folder, GitHub remote via `gh` (visibility to confirm, default private: the asset pack has no license file in the folder).
- Commits: no Co-Authored-By trailer.

## Facts established
- Folder is already a Godot 4.7 project (`project.godot`, Mobile renderer, `[dotnet]` section, `.godot/` ignored). Not a git repo yet. `addons/godot_mcp_toolkit` is present but not enabled and there is no `.mcp.json` (README: Project > Tools > MCP Toolkit > Write .mcp.json; needs Node 22+, Node 24 is installed).
- Asset frame sizes (measured from PNG headers): Char_one walk/idle strips 96x16/17 = 6 frames of 16x16/17; sword attack strip 138x23 = 6 frames of 23x23; skeleton walk/idle 96x17 = 6 frames; Tree.png 48x54; Rock.png 15x15; Rock2.png 14x8; Tilesets are 80x64 = 5x4 cells of 16px.
- Tileset caveat (viewed at 8x with a grid overlay): `TS_Water.png`, `TS_Dirt_Water.png` are NOT a standard 3x3 or 47-tile autotile sheet. Pond outlines sit about 8px inside the cells. There is one big rectangular pond block, one small pond, and one small "grass island in water" block. Treat terrain auto-tiling as unproven until Phase 2.

## Phase 0: Documentation discovery (done)
**How this serves the primary goal:** it fixes the exact Godot 4.7 APIs so later phases copy documented calls instead of guessing, and it surfaces the one genuinely risky area (scene tiles and tileset layout).

Sources read (docs.godotengine.org/en/stable): class_tilemaplayer, class_tileset, class_tilesetscenescollectionsource, tutorials/2d/using_tilesets, using_tilemaps, multiple_resolutions, using_character_body_2d, class_characterbody2d, class_spriteframes, class_animatedsprite2d, class_atlastexture, class_area2d, class_physicsdirectspacestate2d, class_physicsshapequeryparameters2d, physics_introduction, class_input, class_camera2d, class_canvaslayer, groups, class_tween, class_staticbody2d.

### Allowed APIs
- `TileMapLayer.set_cell(coords: Vector2i, source_id := -1, atlas_coords := Vector2i(-1,-1), alternative_tile := 0)`, `erase_cell(coords)`, `local_to_map(Vector2)`, `map_to_local(Vector2i)`, `get_cell_tile_data(coords)`, `get_used_cells()`, `set_cells_terrain_connect(cells, terrain_set, terrain, ignore_empty_terrains := true)`. Property `tile_set`, `y_sort_origin`.
- `TileSet.add_physics_layer()`, `add_terrain_set()`, `add_source(source, id_override)`. `TileSetScenesCollectionSource.create_scene_tile(packed_scene, id_override := -1)`, `get_scene_tile_scene(id)`, `remove_scene_tile(id)`.
- Painting a scene tile from code (inference, test it): `set_cell(cell, scene_source_id, Vector2i.ZERO, scene_tile_id)`.
- `CharacterBody2D`: `motion_mode = MOTION_MODE_FLOATING`, `velocity` (px/s, no delta), `move_and_slide()` with no arguments. `Input.get_vector(left, right, up, down)`.
- `SpriteFrames.add_animation`, `add_frame(anim, texture, duration := 1.0, at_position := -1)`, `set_animation_speed`, `set_animation_loop` (deprecated but works) or `set_animation_loop_mode`. `AnimatedSprite2D.play(name)`, `stop()`, `animation_finished`, `flip_h`, `centered`. `animation_finished` does not fire on looping animations. `play()` with the same name does not restart.
- Hit test, synchronous: `get_world_2d().direct_space_state.intersect_shape(PhysicsShapeQueryParameters2D, max_results := 32)` returns `Array[Dictionary]` with key `collider`. Query properties: `shape`, `transform`, `collision_mask`, `collide_with_bodies`. Call from `_physics_process` or after `await get_tree().physics_frame`.
- Mouse: `CanvasItem.get_global_mouse_position()`, `Input.is_action_just_pressed`, `MOUSE_BUTTON_LEFT`, `_unhandled_input`.
- Targets: duck typing, `if c.has_method("take_hit"): c.take_hit(1)`.
- HUD: `CanvasLayer` > `Label`. `Tween`: `create_tween().tween_property(node, "modulate", Color.WHITE, 0.15)`.
- Layers and masks: `set_collision_layer_value(n, bool)`, `set_collision_mask_value(n, bool)`.

### Anti-patterns (do not use)
`TileMap` node and `set_cell(layer, ...)` (deprecated; use `TileMapLayer`). `KinematicBody2D`, `move_and_slide(vel, up)`, `Camera2D.current`, `smoothing_enabled`, `BUTTON_LEFT`, Tween node and `interpolate_property`. `y_sort_enabled` is not a TileMapLayer property (it is inherited from CanvasItem). Do not read `Area2D.get_overlapping_bodies()` in the same frame as moving or enabling it. Do not hand-write the `[input]` section of project.godot (docs do not describe it): create actions in the editor Input Map or via the MCP tool.

### Documented gaps, to be settled by Phase 2 experiments
Scene tile runtime behaviour: are instances children of the layer, what is their origin and offset, how does `erase_cell` free them, how do they Y-sort against the player, how is a 48x54 tree placed on a 16px grid. Y-sort of CharacterBody2D against the layer (inferred only). Exact `[input]` format. Whether the default texture filter is already Nearest (set it explicitly in Project Settings and look at the game).

## Phase 1: Repo and project setup
**How this serves the primary goal:** a clean, versioned project with pixel-art settings and input actions is the base every later phase builds on.
- `git init`, branch `main`. Keep existing `.gitignore` (`.godot/`, `/android/`). Add `*.import` handling is Godot default, so commit them. Commit the folder, including `Tiny Adventure Pack Plus/` and the PDF. Commit messages carry no Co-Authored-By trailer.
- Ask the user to confirm visibility, then `gh repo create Driftlands --private --source=. --push` (use `--public` only if the user says so).
- In the editor: Project Settings > Rendering > Textures > Default Texture Filter = Nearest. Stretch mode stays `canvas_items` for now (the docs' pixel-art recommendation is `viewport` + `integer`; decide after seeing the game). Input Map actions: `move_up/down/left/right` (W/A/S/D) and `attack` (left mouse), added via the editor or the MCP tool `input_map_event`, never by hand-editing.
- Optional: enable the MCP toolkit plugin and write `.mcp.json` so Claude can build scenes. If skipped, scenes are built in the editor or as `.tscn` text.
- Verify: `git log` shows one commit, `git remote -v` shows origin, project opens headless: `Godot_..._console.exe --headless --path . --quit` exits 0.

## Phase 2: Island tilemap (spike first)
**How this serves the primary goal:** without a walkable island with water edges there is no place to play.
- Pick the grass sheet (`TS_Water.png`) over the dirt one. Copy the PNG into the project root assets folder, create `world.tscn` with a `Node2D` (Y-sort on) containing a `TileMapLayer` (Ground).
- Spike, 30 minutes at most: slice the sheet in the TileSet editor, check how the pond block and the island block line up with the 16px grid. If a terrain set does not give a usable shape, fall back to painting cells by hand with the single full-water cell (atlas 1,0) and the single full-grass cells. A rectangular island is acceptable for the prototype.
- Add a TileSet physics layer, then a collision polygon on the water cells so the player cannot swim.
- Reference: using_tilesets (physics layers, terrains), class_tilemaplayer (`set_cell`, `set_cells_terrain_connect`).
- Verify: open `world.tscn`, island visible with water around it; later, player blocked at the shore.
- Guard: do not generate the island from code or noise.

## Phase 3: Player
**How this serves the primary goal:** "move" is the first of the three actions.
- `player.tscn`: `CharacterBody2D` (floating mode) + `CollisionShape2D` + `AnimatedSprite2D` (`centered = false`, or snap 2D transforms to pixel) + `Camera2D` (zoom 3, smoothing off at first).
- Build `SpriteFrames` from `Char_one/Idle/*` and `Walk/*` (6 frames each, 4 directions; left and right strips exist separately so no flip needed) and `Attack/Sword/*` (6 frames of 23x23, loop off). Use the editor's "Add frames from a Sprite Sheet" with Horizontal 6, Vertical 1, or the documented `AtlasTexture` loop.
- `player.gd`: `velocity = Input.get_vector("move_left","move_right","move_up","move_down") * speed; move_and_slide()`. Pick the animation from the last facing direction.
- Verify: run the scene, walk in 4 directions, animations change, shore blocks.
- Guard: no `KinematicBody2D`, no delta on velocity.

## Phase 4: Harvestables, skeleton and the attack
**How this serves the primary goal:** attack, chop and mine are the other three actions, and they share one mechanism.
- One tiny script `hittable.gd` (`@export var hits := 3`, `signal died`, `func take_hit(dmg := 1)` that decrements, flashes with a tween, and `queue_free()` at zero). Reuse it for tree, rock and skeleton.
- `tree.tscn` (from `Other/Misc/Tree/Tree.png`), `rock.tscn` (`Rock.png`), `skeleton.tscn` (`Enemies/Skeleton/Idle` strips). Each is a `StaticBody2D` or `CharacterBody2D` with a shape and the `hittable.gd`.
- Add the tree and rock to a `TileSetScenesCollectionSource` (TileSet editor, Scenes Collection, Quick Load) and paint a few on an Objects `TileMapLayer`. Run the Phase 0 experiment: print `get_children()` after painting, check position, Y-sort, and that `queue_free()` on the scene removes it cleanly. If scene tiles misbehave, fall back to placing the scenes by hand (this was the user's stated third option).
- Attack in `player.gd`: on `attack` pressed, compute `dir = (get_global_mouse_position() - global_position)`, snap to the dominant axis, play the attack animation, then call `intersect_shape` with a small rectangle placed 12 px ahead, and call `take_hit(1)` on each `collider` that `has_method("take_hit")`. Use a cooldown so one click equals one swing.
- Verify: three clicks remove a tree or a rock or the skeleton; a click away from them does nothing.
- Guard: no AI, no player health, no inventory, no tool switching.

## Phase 5: HUD counters
**How this serves the primary goal:** the counters are the visible proof that harvesting worked.
- `CanvasLayer` > `Label` in `world.tscn`, `Wood: 0  Stone: 0`. Trees and rocks emit `died`, and the world script adds 1 wood or 1 stone (or 3, tweak later) and updates the label. Two ints in one script.
- Verify: chopping a tree raises Wood, mining a rock raises Stone, killing the skeleton changes neither.

## Phase 6: Verification
**How this serves the primary goal:** confirms the prototype does exactly the agreed loop and nothing more.
- Headless boot with no errors: `Godot_..._console.exe --headless --path . --quit-after 120` and check the output for `ERROR` and `SCRIPT ERROR`.
- Play through once: walk, get blocked by water, kill the skeleton, chop every tree, mine every rock, counters correct.
- Grep checks: `grep -rE "KinematicBody2D|TileMap\b|BUTTON_LEFT|interpolate_property" --include=*.gd --include=*.tscn .` must return nothing outside addons.
- `git status` clean, `git log` has no Co-Authored-By trailer (`git log --format=%B | grep -i co-authored` returns nothing).

## Not now
Inventory, crafting, machines, more islands, skills, respawn, player health, skeleton AI, audio, particles, screen shake, save/load, gamepad, menus.

## Alternatives considered
- Terrain auto-tiling vs hand-painted cells: auto-tiling is the editor-native path, but the sheet is non-standard; hand painting is the safe fallback.
- Scene tiles vs hand-placed scenes: scene tiles match your request, and each is instanced separately, which is fine at this size.
- Hit test: `intersect_shape` (chosen, synchronous, no stale overlaps) vs a child `Area2D` (needs an `await physics_frame`).
- Stretch: `canvas_items` is kept now for simplicity; `viewport` + integer scaling is the docs' pixel-art recommendation and is cheap to switch later.
- Language: GDScript chosen; the `[dotnet]` section in `project.godot` can stay unused.

## Outcome (all phases built and verified)
Deviations from the plan, and why:
- **Island = dual-grid.** The tileset sheet is a half-cell-offset ("dual grid") set. `scripts/world.gd` (@tool) fills the `Ground` layer from the land cells you paint in `Data` (use any tile, e.g. atlas 2,0). Water collision comes from per-quad polygons in `tileset.tres`. Limit: no tiles for diagonal-only corners (1001, 0110), keep outlines free of them.
- **Attack = the pack's attack strips.** Frame sizes differ per direction (down 23x23, left/right 16x21, up 23x18), so `scripts/player.gd` shifts the sprite by a fixed `ATTACK_SHIFT` per direction to keep the head over the idle head (measured from the hair-pixel centroid). Hit test is `intersect_shape` at swing start.
- **Hover highlight (Forager-style).** Each physics frame the player runs the same box query a swing toward the cursor would use, and the hit objects get the white-rim shader `shaders/outline.gdshader` via `set_hover()`. So the highlight always matches what a click would hit.
- **Texture filter:** `default_texture_filter` value 0 is Nearest (the doc fetch implied 1; 1 is Linear).
- **Scene tiles** (verified in engine): instances are children of the `Objects` layer, origin at the cell centre, they Y-sort with the player, and `erase_cell` frees them.
- Skeleton is a static dummy (`StaticBody2D`), not placed as a tile.
- Scenes/tileset were generated by headless scripts, but they are plain `.tscn`/`.tres` files now: edit them in the editor.

Checks run: headless boot with no errors or warnings; grep for Godot 3 leftovers returned nothing; scripted play test: shore blocks the player on all sides, 3 swings remove a tree (Wood 1), a rock (Stone 1) and the skeleton (no counter change).

# Feature: inventory and crafting (branch `feature/inventory-crafting`)

## Goal
The one-pager MVP item "basic inventory with sorting and stacking", selling point 5 (freely rearranged inventory, items assigned to hotbar slots), and the start of crafting.

## What was built
- **Data as resources.** `ItemData` (name, icon, kind, max stack, tool type, power) and `Recipe` (inputs, output, station) are `.tres` files under `data/`, so the game designer can add and tune items without code. `data/recipe_book.tres` sets which recipes the crafting menu shows, in order.
- **Inventory logic** in `Inventory` (`scripts/items/inventory.gd`), separate from the UI and from the player, so chests and machines can reuse it. 32 slots for the player: 8 hotbar + 24 bag. Add (top up, then empty slots), remove (bag first, so the hotbar keeps its items longest), move/merge/swap, split, transfer, sort.
- **Hotbar rules.** New tools go to the hotbar first, resources to the bag first, so gathering never pushes into the slots the player set up. Sort only touches the bag.
- **Autoload `PlayerData`** holds the inventory and the selected slot, and emits `gained` / `inventory_full` for the pickup messages.
- **Crafting menu (Q), separate from the inventory (Tab / I), laid out like Rust's:** categories on the left (All, Favorites, then the recipe categories with counts; empty ones dimmed), a search box that looks through every category, a grid of recipe icons (dimmed when you can't afford them), and a details panel with the icon, description, craft time, a Favorite toggle, an Amount / Item / Total / Have table (missing amounts in red), a -/+ amount and Craft.
- **Crafting queue** (autoload `Crafting`, `scripts/crafting.gd`): Craft takes the ingredients right away and queues the job (8 jobs at most). Items are made one at a time, each taking the recipe's `craft_time`, and are shown bottom right with a countdown. Clicking a queued job cancels it and refunds what was not made yet. If the inventory is full when a craft finishes, the job waits ("Full") instead of losing the item.
- **Menus freeze the player** (`PlayerData.menu_open`), so typing in the search box does not walk around, and letter hotkeys are ignored while a text box has focus.
- **Tools matter.** Hittables have `weak_to`; the held tool's `power` applies when its `tool_type` matches, otherwise 1. Trees and rocks drop 3 each so the 4 trees and 3 rocks on the island are enough for all three tools.
- **UI** is scenes plus one theme (`scenes/ui/theme.tres`), so the artist can restyle it in the theme editor. The old Wood/Stone label is gone; the hotbar and pickup messages replace it.
- **Icons.** Stone and sword come from the asset pack; wood, axe and pickaxe are generated 16x16 placeholders in the pack's palette, to be replaced.
- **Tests** in `tests/tests.tscn`: 60 checks, unit tests on `Inventory`, `Recipe` and the crafting queue, plus a scripted play-through of the world scene including the crafting menu. All pass headless.

## Decisions taken without asking (easy to change)
- Hotbar size 8, bag 24, stack size 99.
- Recipes: Stone Axe (3 wood, 2 stone), Stone Pickaxe (3 wood, 3 stone), Stone Sword (2 wood, 3 stone), 3 s each. Tools do 2 damage to their target type.
- Categories: Tools, Weapons, Buildings, Machines, Resources, Food. Favorites are not saved yet (there is no save system).
- Items that do not fit are lost (with an "Inventory full!" message); there are no ground drops yet.

## Not in this step
Placing buildings (furnace, drill), station recipes, ground item drops, resources regrowing, saving the inventory (items have an `id` for that), ores and the other islands.
