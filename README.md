# Driftlands

2D top-down sandbox about gathering, crafting and automation (see `Forager v2 (1).pdf` for the one-pager). This repo holds the first small prototype.

## What the prototype does
Walk around a small island, swing toward the mouse to hit a skeleton dummy, chop trees and mine rocks. Wood and stone go into an inventory; craft a stone axe, pickaxe or sword from them in the crafting menu. A tool in the selected hotbar slot hits its own targets harder (axe: trees, pickaxe: rocks, sword: enemies). Craft a furnace, place it on the island, and smelt iron ore from the iron rocks into iron ingots, burning wood. Trees, rocks and iron rocks grow back over time.

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
| Click a queued item (bottom right) | Cancel it and get the ingredients back (refused, with "Inventory full!", if they would not fit) |
| With a building (furnace) selected: left click | Place it on the highlighted cell (green = OK, red = blocked or too far) |
| Left click next to a building | Open it (the furnace screen) instead of swinging |
| In the furnace: drag or Shift + click | Move items in and out. Shift+click puts fuel and ore in the right slot by itself |
| Pick up (furnace screen) | Get the furnace and everything in it back (refused if it doesn't all fit) |

The object a swing would hit gets a white outline. Trees, rocks and the skeleton take 3 hits by hand, 2 with the matching stone tool. A tree gives 3 wood, a rock 3 stone. Recipes you can't afford are dimmed, and the ingredient table shows the missing ones in red. If the inventory is full when a craft finishes, it waits in the queue until there is room. The player stands still while a menu is open. The furnace burns fuel only while it is smelting (wood lasts 8 s, 2 iron ore make 1 ingot in 4 s) and its screen says why it is idle. Iron rocks take 4 hits and give 2 iron ore. Every 6 s a new tree, rock or iron rock appears on a free cell, up to 14 on the island. New tools and buildings go to the hotbar, resources to the bag, and **Sort** only reorders the bag, so the hotbar stays the way you set it up.

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
| `scenes/` | `world` (the level), `player`, `tree`, `rock`, `iron_rock`, `skeleton`, `hud`; `buildings/furnace` |
| `scripts/` | `world.gd` (island tiles), `player.gd` (move, attack, hover), `hittable.gd` (hits, drops), `hud.gd` (hotbar, pickup messages, opens the inventory), `player_data.gd` (autoload `PlayerData`: the player's inventory and hotbar selection), `crafting.gd` (autoload `Crafting`: recipe list, favorites, crafting queue), `placer.gd` (building placement and its ghost), `spawner.gd` (resources growing back), `highlight.gd` (the hover outline) |
| `scripts/buildings/` | `Building` (base: open, pick up, contents) and `furnace.gd` (fuel, smelting) |
| `scripts/items/` | `ItemData`, `Recipe`, `RecipeBook` (resource types), `Inventory` and `ItemStack` (slot logic, reusable for chests and machines later) |
| `scripts/ui/`, `scenes/ui/` | Slot, slot grid, inventory screen, crafting screen, crafting queue, furnace screen, and `theme.tres` (all UI colours and fonts) |
| `data/items/`, `data/recipes/`, `data/recipe_book.tres` | One `.tres` per item and per recipe; the book lists which recipes the crafting menu shows |
| `art/` | `icons/` 16x16 item icons, `buildings/` (furnace strip: off + 2 lit frames), `resources/` (iron rock). All of these are placeholders except the stone and sword icons, which come from the pack |
| `tests/` | Automated checks (see below) |
| `shaders/outline.gdshader` | Hover highlight |
| `tileset.tres` | Ground tiles with water collision, plus the scene tiles: 1 tree, 2 rock, 3 iron rock |
| `Tiny Adventure Pack Plus/` | Third-party art (no license file included, check its terms) |
| `PLAN.md` | The build plan, decisions and what changed |
| `addons/godot_mcp_toolkit/` | Optional editor plugin for AI assistants; disabled by default |

## Editing the island
Open `scenes/world.tscn`. Paint **land** on the `Data` layer with any ground tile (atlas 2,0); the `Ground` layer is filled automatically when the scene loads, with the shoreline edges and water collision. Avoid shapes where land touches only at a corner (no tile exists for that). Trees, rocks and iron rocks are painted on the `Objects` layer as scene tiles from the tileset's scenes collection. Placed buildings go under the `Buildings` node.

## Adding a harvestable
Make a `StaticBody2D` scene with a sprite (origin at its base), a collision shape, and `scripts/hittable.gd`. Set `Hits`, `Drop` (an item from `data/items/`), `Drop Count` and `Weak To` (`axe`, `pickaxe` or `sword`) in the inspector. To let it grow back, add the scene to the tileset's scenes collection and give its tile id a weight in the `Spawner` node of `world.tscn` (`Weights`; `Interval` and `Max Resources` are there too).

## Adding a building
1. Make a scene under `scenes/buildings/`: a `StaticBody2D` with a script that extends `Building` (`scripts/buildings/building.gd`), a sprite whose base sits on the node's origin, and a small collision shape at the base. It takes one grid cell. Override `interact()` if clicking it should do something; give it an `inventory` if it stores items (they come back with Pick up).
2. Make its item: kind **Building**, and set **Building** (under the Building group) to the scene.
3. Add a recipe for it (category Buildings) and put it in the recipe book.

## Adding an item or a recipe
All in the editor, no code:
1. **Item:** in `data/items/`, right-click > New Resource > `ItemData`. Set id, name, a 16x16 icon, kind (Tool / Building / Resource) and max stack (1 for tools). Tools also get a tool type and power (damage per swing against targets weak to that tool type).
2. **Recipe:** in `data/recipes/`, New Resource > `Recipe`. Set the output, the output count, the inputs (item > amount), the category (the crafting menu tab) and the craft time in seconds. Leave station empty for crafting by hand. For a furnace recipe set station to `furnace` and give it exactly one input; it then smelts in the furnace and shows in the crafting menu as "Needs a Furnace". An item burns as fuel when its **Fuel Time** is above 0.
3. Open `data/recipe_book.tres` and add the recipe to the list. The crafting menu shows recipes in that order.

New categories go at the end of the `Category` list in `scripts/items/recipe.gd`, so existing recipes keep theirs.

## Tests
From the project folder (use your own path to the Godot console exe):
```
Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/tests.tscn
```
It prints `N/N checks passed`, or a `FAIL:` line per broken check, and the exit code is the number of failures. It covers the inventory rules (stacking, moving, splitting, sorting), the crafting queue (timing, cancel and refund, waiting when full) and a scripted play-through in the real world scene (chop, mine, use the crafting menu's categories, search and amount, queue an axe, drag it, select it, chop faster), the furnace (fuel, smelting, idle and full output, pick up) and a building play-through (mine iron, regrowth, craft and place a furnace with the invalid spots, open it, shift+click ore and wood in, smelt an ingot, pick it up). Without `--headless` and with `-- --shots=<folder>` added at the end, it also saves screenshots of the hotbar, the inventory, the crafting menu, a lit furnace and the furnace screen.

## Git
Commit the `.uid` and `.import` files Godot generates (they keep resource references stable). Never commit `.godot/`.
