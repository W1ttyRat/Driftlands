# Driftlands

2D top-down sandbox about gathering, crafting and automation (see `Forager v2 (1).pdf` for the one-pager). This repo holds the first small prototype.

## What the prototype does
Walk around a small island, swing toward the mouse to hit a skeleton dummy, chop trees and mine rocks. Wood and stone go into an inventory; craft a stone axe, pickaxe or sword from them in the crafting menu. A tool in the selected hotbar slot hits its own targets harder (axe: trees, pickaxe: rocks, sword: enemies).

| Input | Action |
|---|---|
| W A S D | Move |
| Left click | Swing toward the cursor (4 directions) |
| 1-8 / mouse wheel | Pick a hotbar slot |
| Tab or I | Open / close the inventory |
| Q | Open / close the crafting menu |
| Esc | Close whichever menu is open |
| In the inventory: drag | Move or swap a stack, or merge it onto the same item |
| Shift + click | Send a stack between hotbar and bag |
| Right click | Split a stack in half |
| In crafting: categories, search | Filter the recipe grid (search looks through every category) |
| Click a recipe, -/+ or type an amount, Craft | Queue it. Ingredients are taken right away, each item takes its craft time |
| Click a queued item (bottom right) | Cancel it and get the ingredients back |

The object a swing would hit gets a white outline. Trees, rocks and the skeleton take 3 hits by hand, 2 with the matching stone tool. A tree gives 3 wood, a rock 3 stone. Recipes you can't afford are dimmed, and the ingredient table shows the missing ones in red. If the inventory is full when a craft finishes, it waits in the queue until there is room. The player stands still while a menu is open. New tools go to the hotbar, resources to the bag, and **Sort** only reorders the bag, so the hotbar stays the way you set it up.

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
| `scripts/` | `world.gd` (island tiles), `player.gd` (move, attack, hover), `hittable.gd` (hits, drops), `hud.gd` (hotbar, pickup messages, opens the inventory), `player_data.gd` (autoload `PlayerData`: the player's inventory and hotbar selection), `crafting.gd` (autoload `Crafting`: recipe list, favorites, crafting queue) |
| `scripts/items/` | `ItemData`, `Recipe`, `RecipeBook` (resource types), `Inventory` and `ItemStack` (slot logic, reusable for chests and machines later) |
| `scripts/ui/`, `scenes/ui/` | Slot, slot grid, inventory screen, crafting screen, crafting queue, and `theme.tres` (all UI colours and fonts) |
| `data/items/`, `data/recipes/`, `data/recipe_book.tres` | One `.tres` per item and per recipe; the book lists which recipes the crafting menu shows |
| `art/icons/` | 16x16 item icons. Wood, axe and pickaxe are placeholders; stone and sword come from the pack |
| `tests/` | Automated checks (see below) |
| `shaders/outline.gdshader` | Hover highlight |
| `tileset.tres` | Ground tiles with water collision, plus the tree and rock scene tiles |
| `Tiny Adventure Pack Plus/` | Third-party art (no license file included, check its terms) |
| `PLAN.md` | The build plan, decisions and what changed |
| `addons/godot_mcp_toolkit/` | Optional editor plugin for AI assistants; disabled by default |

## Editing the island
Open `scenes/world.tscn`. Paint **land** on the `Data` layer with any ground tile (atlas 2,0); the `Ground` layer is filled automatically when the scene loads, with the shoreline edges and water collision. Avoid shapes where land touches only at a corner (no tile exists for that). Trees and rocks are painted on the `Objects` layer as scene tiles from the tileset's scenes collection.

## Adding a harvestable
Make a `StaticBody2D` scene with a sprite (origin at its base), a collision shape, and `scripts/hittable.gd`. Set `Hits` and `Drop` (`wood` or `stone`) in the inspector. Set `Hits`, `Drop` (an item from `data/items/`), `Drop Count` and `Weak To` (`axe`, `pickaxe` or `sword`) in the inspector.

## Adding an item or a recipe
All in the editor, no code:
1. **Item:** in `data/items/`, right-click > New Resource > `ItemData`. Set id, name, a 16x16 icon, kind (Tool / Building / Resource) and max stack (1 for tools). Tools also get a tool type and power (damage per swing against targets weak to that tool type).
2. **Recipe:** in `data/recipes/`, New Resource > `Recipe`. Set the output, the output count, the inputs (item > amount), the category (the crafting menu tab) and the craft time in seconds. Leave station empty for crafting by hand; recipes with a station show in the menu but can't be crafted yet.
3. Open `data/recipe_book.tres` and add the recipe to the list. The crafting menu shows recipes in that order.

New categories go at the end of the `Category` list in `scripts/items/recipe.gd`, so existing recipes keep theirs.

## Tests
From the project folder (use your own path to the Godot console exe):
```
Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/tests.tscn
```
It prints `N/N checks passed`, or a `FAIL:` line per broken check, and the exit code is the number of failures. It covers the inventory rules (stacking, moving, splitting, sorting), the crafting queue (timing, cancel and refund, waiting when full) and a scripted play-through in the real world scene (chop, mine, use the crafting menu's categories, search and amount, queue an axe, drag it, select it, chop faster). Without `--headless` and with `-- --shots=<folder>` added at the end, it also saves screenshots of the hotbar, the inventory and the crafting menu.

## Git
Commit the `.uid` and `.import` files Godot generates (they keep resource references stable). Never commit `.godot/`.
