extends Control
## Opens when you click a furnace. Its three slots (fuel, input, output) on top, your bag and
## hotbar below. Drag between them, or Shift+click to send a stack across: fuel lands in the fuel
## slot and ore in the input slot by themselves.

signal close_requested

const SLOT := preload("res://scenes/ui/slot.tscn")
const FURNACE := preload("res://scripts/buildings/furnace.gd")

var furnace: Node

func _ready() -> void:
	%PickUp.pressed.connect(_pick_up)

func open_for(f: Node) -> void:
	furnace = f
	_clear(%FuelSlot)
	_clear(%InputSlot)
	_clear(%OutputSlot)
	_clear(%Bag)
	_clear(%Hotbar)
	var to_player := func(i: int) -> void:
		var s: ItemStack = f.inventory.get_stack(i)
		if s:
			f.inventory.transfer(i, PlayerData.fill_order(s.item), PlayerData.inventory)
	for pair in [[%FuelSlot, FURNACE.FUEL], [%InputSlot, FURNACE.INPUT], [%OutputSlot, FURNACE.OUTPUT]]:
		pair[0].add_child(_slot(f.inventory, pair[1], false, to_player))
	var to_furnace := func(i: int) -> void: PlayerData.inventory.transfer(i, [], f.inventory)
	for i in range(PlayerData.HOTBAR, PlayerData.HOTBAR + PlayerData.BAG):
		%Bag.add_child(_slot(PlayerData.inventory, i, false, to_furnace))
	for i in PlayerData.HOTBAR:
		%Hotbar.add_child(_slot(PlayerData.inventory, i, true, to_furnace))
	%Smelts.text = _smelt_list()

func _slot(inv: Inventory, i: int, hotbar: bool, quick: Callable) -> Control:
	var s := SLOT.instantiate()
	s.inventory = inv
	s.index = i
	s.hotbar = hotbar
	s.on_quick_move = quick
	s.on_split = func(_i: int) -> void: pass
	return s

func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

func _smelt_list() -> String:
	var lines := []
	for r in Crafting.recipes():
		if r.station == FURNACE.STATION:
			for item: ItemData in r.inputs:
				lines.append("%d %s  ->  %d %s   (%ss)" % [r.inputs[item], item.name, r.output_count, r.output.name, str(r.craft_time)])
	var fuels := []
	for item in _fuels():
		fuels.append("%s %ss" % [item.name, str(item.fuel_time)])
	return "Smelts: " + ", ".join(lines) + "\nFuel: " + ", ".join(fuels)

# Fuels the player can know about: inputs and outputs of all recipes with a fuel_time.
func _fuels() -> Array[ItemData]:
	var out: Array[ItemData] = []
	for r in Crafting.recipes():
		for item: ItemData in r.inputs.keys() + [r.output]:
			if item.fuel_time > 0.0 and not item in out:
				out.append(item)
	return out

func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(furnace):
		close_requested.emit()
		return
	%Smelt.value = furnace.progress / furnace.recipe.craft_time if furnace.recipe else 0.0
	%Burn.value = clampf(furnace.burn_left / furnace.burn_total, 0.0, 1.0) if furnace.burn_total > 0.0 else 0.0
	var why: String = furnace.status()
	%Status.text = ("Smelting %s..." % furnace.recipe.output.name) if why == "" and furnace.recipe else why
	%Status.theme_type_variation = &"" if why == "" else &"Hint"

func _pick_up() -> void:
	if furnace.pick_up():
		close_requested.emit()
