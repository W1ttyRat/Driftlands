extends Building
## Smelts what is in its input slot, using the recipes whose station is "furnace"
## (e.g. 2 Iron Ore -> 1 Iron Ingot). Burns fuel (items with fuel_time > 0) only while smelting;
## the part of a piece of fuel that is not used yet stays in the furnace.
## Later, machines can feed it: anything added through `inventory.add()` lands in the right slot.

const FUEL := 0
const INPUT := 1
const OUTPUT := 2
const STATION := "furnace"

var burn_left := 0.0   # seconds of fuel left
var burn_total := 0.0  # seconds the current piece of fuel lasts (for the bar)
var progress := 0.0    # seconds into the current smelt
var recipe: Recipe     # what it is smelting right now, or null

@onready var sprite: AnimatedSprite2D = $Sprite

func _init() -> void:
	inventory = Inventory.new(3)
	inventory.filters = {
		FUEL: func(it: ItemData) -> bool: return it.fuel_time > 0.0,
		INPUT: func(it: ItemData) -> bool: return Crafting.recipe_using(it, STATION) != null,
		OUTPUT: func(_it: ItemData) -> bool: return false,
	}

func interact() -> void:
	PlayerData.open_machine(self)

func is_lit() -> bool:
	return sprite.animation == &"lit"

## What it would smelt now (enough input and room in the output), or null.
func ready_recipe() -> Recipe:
	var input := inventory.get_stack(INPUT)
	if input == null:
		return null
	var r := Crafting.recipe_using(input.item, STATION)
	if r == null or input.count < r.inputs[input.item]:
		return null
	var out := inventory.get_stack(OUTPUT)
	if out and (out.item != r.output or out.count + r.output_count > r.output.max_stack):
		return null
	return r

## Why it is not working, for the screen. "" when it is smelting.
func status() -> String:
	var input := inventory.get_stack(INPUT)
	if input == null:
		return "Put something to smelt in the middle slot."
	var r := Crafting.recipe_using(input.item, STATION)
	if r == null:
		return "The furnace can't smelt %s." % input.item.name
	if input.count < r.inputs[input.item]:
		return "Needs %d %s to smelt." % [r.inputs[input.item], input.item.name]
	if ready_recipe() == null:
		return "Output is full."
	if burn_left <= 0.0 and inventory.get_stack(FUEL) == null:
		return "Needs fuel."
	return ""

func _process(delta: float) -> void:
	var r := ready_recipe()
	if r != recipe:
		recipe = r
		progress = 0.0
	if r == null or (burn_left <= 0.0 and not _refuel()):
		_set_lit(false)
		return
	_set_lit(true)
	burn_left -= delta
	progress += delta
	if progress >= r.craft_time:
		progress -= r.craft_time
		_smelt(r)

func _refuel() -> bool:
	var fuel := inventory.get_stack(FUEL)
	if fuel == null:
		return false
	burn_total = fuel.item.fuel_time
	burn_left += burn_total
	inventory.take(FUEL, 1)
	return true

func _smelt(r: Recipe) -> void:
	var input := inventory.get_stack(INPUT)
	inventory.take(INPUT, r.inputs[input.item])
	var out := inventory.get_stack(OUTPUT)
	if out:
		out.count += r.output_count
	else:
		inventory.slots[OUTPUT] = ItemStack.new(r.output, r.output_count)
	inventory.changed.emit()

func _set_lit(on: bool) -> void:
	sprite.play(&"lit" if on else &"off")
