class_name ItemStack
extends RefCounted
## What one inventory slot holds: an item and how many.

var item: ItemData
var count: int

func _init(p_item: ItemData, p_count := 1) -> void:
	item = p_item
	count = p_count

func copy() -> ItemStack:
	return ItemStack.new(item, count)
