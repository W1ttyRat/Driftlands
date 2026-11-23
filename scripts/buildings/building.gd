class_name Building
extends StaticBody2D
## Something the player placed (see placer.gd). Clicking it next to it calls interact().
## pick_up() turns it back into its item, together with anything stored inside.

## The item this was placed from; set by the placer, given back by pick_up().
var item: ItemData
## What is stored inside (a furnace's fuel, input and output), or null.
var inventory: Inventory

func set_hover(on: bool) -> void:
	Highlight.set_on(self, on)

## Called when the player clicks it. Buildings with a menu override this.
func interact() -> void:
	pass

## Puts this building and its contents into the player's inventory and removes it.
## Refused (returns false, nothing changes) if not all of it fits.
func pick_up() -> bool:
	var back: Array = []
	if item:
		back.append([item, 1])
	if inventory:
		for s in inventory.slots:
			if s:
				back.append([s.item, s.count])
	var inv := PlayerData.inventory
	var before := inv.snapshot()
	for pair in back:
		if inv.add(pair[0], pair[1], PlayerData.fill_order(pair[0])) > 0:
			inv.restore(before)
			PlayerData.inventory_full.emit(pair[0])
			return false
	for pair in back:
		PlayerData.gained.emit(pair[0], pair[1])
	queue_free()
	return true
