class_name Recipe
extends Resource
## Turns `inputs` into `output_count` x `output`. Each recipe is a .tres file in data/recipes/
## and is listed in data/recipe_book.tres so it shows up in the crafting menu (Q).

## Crafting menu tabs. Add new ones at the end so existing recipes keep theirs.
enum Category { TOOLS, WEAPONS, BUILDINGS, MACHINES, RESOURCES, FOOD }

@export var output: ItemData
@export_range(1, 999) var output_count := 1
@export var inputs: Dictionary[ItemData, int] = {}
@export var category := Category.TOOLS
## Seconds per craft in the queue.
@export_range(0.0, 600.0, 0.1, "suffix:s") var craft_time := 3.0
## Where it can be made. "" = by hand. Others (e.g. "furnace") show in the menu but cannot be crafted yet.
@export var station := ""

static func category_name(c: Category) -> String:
	return Category.keys()[c].capitalize()

func by_hand() -> bool:
	return station == ""

## The inputs for crafting this `times` times.
func costs(times := 1) -> Dictionary:
	var out := {}
	for item in inputs:
		out[item] = inputs[item] * times
	return out

## How many times `inv` can pay for this recipe.
func max_crafts(inv: Inventory) -> int:
	var n := 999
	for item in inputs:
		@warning_ignore("integer_division")
		n = mini(n, inv.count(item) / inputs[item])
	return n
