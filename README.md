# Driftlands

2D top-down sandbox about gathering, crafting and automation (see `Forager v2 (1).pdf` for the one-pager). This repo holds the first small prototype.

## What the prototype does
Walk around a small island, swing a sword toward the mouse to hit a skeleton dummy, and chop trees / mine rocks. Wood and Stone counters show at the top-left. Nothing else yet.

| Input | Action |
|---|---|
| W A S D | Move |
| Left click | Swing the sword toward the cursor (4 directions) |

The object a swing would hit gets a white outline. Trees, rocks and the skeleton take 3 hits.

## Setup
1. Install **Godot 4.7 or newer** (https://godotengine.org/download). The standard build is enough; the .NET/mono build is not needed, the game is pure GDScript.
2. Clone the repo:
   ```bash
   git clone https://github.com/W1ttyRat/Driftlands.git
   ```
3. Open Godot, click **Import**, choose `project.godot`. The first open imports the assets (a short wait; Godot creates the git-ignored `.godot/` folder).
4. Press **F5**. The main scene is `scenes/world.tscn`.

Windows note: the project is set to Direct3D 12 (`project.godot`, `rendering_device/driver.windows`). If your GPU doesn't support it, change that setting under Project Settings > Rendering > Rendering Device > Driver.

## Project layout
| Path | What |
|---|---|
| `scenes/` | `world` (the level), `player`, `tree`, `rock`, `skeleton`, `hud` |
| `scripts/` | `world.gd` (island tiles), `player.gd` (move, attack, hover), `hittable.gd` (3 hits, drops), `hud.gd` (counters) |
| `shaders/outline.gdshader` | Hover highlight |
| `tileset.tres` | Ground tiles with water collision, plus the tree and rock scene tiles |
| `Tiny Adventure Pack Plus/` | Third-party art (no license file included, check its terms) |
| `PLAN.md` | The build plan, decisions and what changed |
| `addons/godot_mcp_toolkit/` | Optional editor plugin for AI assistants; disabled by default |

## Editing the island
Open `scenes/world.tscn`. Paint **land** on the `Data` layer with any ground tile (atlas 2,0); the `Ground` layer is filled automatically when the scene loads, with the shoreline edges and water collision. Avoid shapes where land touches only at a corner (no tile exists for that). Trees and rocks are painted on the `Objects` layer as scene tiles from the tileset's scenes collection.

## Adding a harvestable
Make a `StaticBody2D` scene with a sprite (origin at its base), a collision shape, and `scripts/hittable.gd`. Set `Hits` and `Drop` (`wood` or `stone`) in the inspector. Add new drop kinds in `scripts/hud.gd`.

## Git
Commit the `.uid` and `.import` files Godot generates (they keep resource references stable). Never commit `.godot/`.
