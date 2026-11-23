extends Node
## Autoload "PlayerData": the player's inventory and hotbar selection, reachable from the
## player, the HUD and (later) machines. Slots 0..HOTBAR-1 are the hotbar, the rest the bag.

signal selected_changed
signal gained(item: ItemData, amount: int)
signal inventory_full(item: ItemData)

const HOTBAR := 8
const BAG := 24

var inventory := Inventory.new(HOTBAR + BAG)
var selected := 0
## The inventory or crafting screen is open: the player stands still (typing in search must not walk).
var menu_open := false

func hotbar_slots() -> Array:
	return range(HOTBAR)

func bag_slots() -> Array:
	return range(HOTBAR, HOTBAR + BAG)

func is_hotbar(i: int) -> bool:
	return i < HOTBAR

## New tools go to the hotbar first so they are ready to use; everything else goes to the bag first,
## so wood and stone do not push into the slots you set up.
func fill_order(item: ItemData) -> Array:
	if item.kind == ItemData.Kind.TOOL:
		return hotbar_slots() + bag_slots()
	return bag_slots() + hotbar_slots()

## Puts items in the inventory. Returns how many did not fit (those are lost).
func give(item: ItemData, amount := 1) -> int:
	var left := inventory.add(item, amount, fill_order(item))
	if left < amount:
		gained.emit(item, amount - left)
	if left > 0:
		inventory_full.emit(item)
	return left

## The item in the selected hotbar slot, or null.
func held() -> ItemData:
	var s := inventory.get_stack(selected)
	return s.item if s else null

func select(i: int) -> void:
	selected = posmod(i, HOTBAR)
	selected_changed.emit()

## Shift+click: hotbar <-> bag.
func quick_move(i: int) -> void:
	inventory.transfer(i, bag_slots() if is_hotbar(i) else hotbar_slots())

func split(i: int) -> void:
	inventory.split(i, bag_slots() + hotbar_slots())

func sort_bag() -> void:
	inventory.sort_range(HOTBAR, HOTBAR + BAG)

func _unhandled_input(event: InputEvent) -> void:
	for i in HOTBAR:
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			select(i)
			return
	if event.is_action_pressed("hotbar_next"):
		select(selected + 1)
	elif event.is_action_pressed("hotbar_prev"):
		select(selected - 1)
