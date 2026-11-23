class_name Inventory
extends RefCounted
## A fixed number of slots, each empty (null) or holding one ItemStack.
## The player's bag and machines (the furnace) use it.
## "order" arguments are lists of slot indices, saying which slots to try and in what order.

signal changed

var slots: Array[ItemStack] = []
## Optional per-slot rules: slot index -> Callable(item: ItemData) -> bool. A furnace's fuel slot
## only takes fuel, its output slot takes nothing from outside. Slots without a rule take anything.
var filters := {}

func _init(size: int) -> void:
	slots.resize(size)

func size() -> int:
	return slots.size()

func get_stack(i: int) -> ItemStack:
	return slots[i]

func count(item: ItemData) -> int:
	var n := 0
	for s in slots:
		if s and s.item == item:
			n += s.count
	return n

func accepts(i: int, item: ItemData) -> bool:
	return not filters.has(i) or filters[i].call(item)

## `costs` maps ItemData to an amount.
func has_all(costs: Dictionary) -> bool:
	for item in costs:
		if count(item) < costs[item]:
			return false
	return true

## How many of `item` would fit in the slots in `order` (default: all).
func space_for(item: ItemData, order: Array = []) -> int:
	if order.is_empty():
		order = range(slots.size())
	var n := 0
	for i in order:
		var s := slots[i]
		if not accepts(i, item):
			continue
		if s == null:
			n += item.max_stack
		elif s.item == item:
			n += item.max_stack - s.count
	return n

## Adds `amount`: first tops up stacks of the same item, then fills empty slots, both in `order`.
## Returns how many did not fit.
func add(item: ItemData, amount: int, order: Array = []) -> int:
	if order.is_empty():
		order = range(slots.size())
	var left := amount
	for i in order:
		var s := slots[i]
		if left > 0 and s and s.item == item and s.count < item.max_stack and accepts(i, item):
			var n := mini(left, item.max_stack - s.count)
			s.count += n
			left -= n
	for i in order:
		if left > 0 and slots[i] == null and accepts(i, item):
			var n := mini(left, item.max_stack)
			slots[i] = ItemStack.new(item, n)
			left -= n
	if left != amount:
		changed.emit()
	return left

## Removes `amount`, taking from the last slots first (the bag before the hotbar).
## Returns false and changes nothing if there is not enough.
func remove(item: ItemData, amount: int) -> bool:
	if count(item) < amount:
		return false
	var left := amount
	for i in range(slots.size() - 1, -1, -1):
		var s := slots[i]
		if left > 0 and s and s.item == item:
			var n := mini(left, s.count)
			s.count -= n
			left -= n
			if s.count == 0:
				slots[i] = null
	changed.emit()
	return true

## Drag and drop. Moves `amount` (default: all) from slot `from` onto slot `to`.
## Onto the same item it merges as much as fits; onto a different item a whole stack swaps places.
func move(from: int, to: int, amount := -1) -> void:
	move_to(from, self, to, amount)

## Like move(), but into slot `to` of `dest`, which can be another inventory (player <-> furnace).
## Respects both sides' slot rules.
func move_to(from: int, dest: Inventory, to: int, amount := -1) -> void:
	var a := slots[from]
	if a == null or (dest == self and from == to) or not dest.accepts(to, a.item):
		return
	if amount < 0 or amount > a.count:
		amount = a.count
	var b := dest.slots[to]
	if b == null:
		if amount == a.count:
			dest.slots[to] = a
			slots[from] = null
		else:
			dest.slots[to] = ItemStack.new(a.item, amount)
			a.count -= amount
	elif b.item == a.item:
		var n := mini(amount, a.item.max_stack - b.count)
		if n == 0:
			return
		b.count += n
		a.count -= n
		if a.count == 0:
			slots[from] = null
	elif amount == a.count and accepts(from, b.item):
		dest.slots[to] = a
		slots[from] = b
	else:
		return
	changed.emit()
	if dest != self:
		dest.changed.emit()

## Moves the stack in slot `i` into the slots in `targets` of `dest` (default: this inventory),
## topping up first. An empty `targets` means every slot that accepts it. What does not fit stays.
func transfer(i: int, targets: Array, dest: Inventory = null) -> void:
	if dest == null:
		dest = self
	var s := slots[i]
	if s == null:
		return
	slots[i] = null
	if dest == self:
		targets = targets.filter(func(t: int) -> bool: return t != i)
	var left := dest.add(s.item, s.count, targets)
	if left > 0:
		s.count = left
		slots[i] = s
	changed.emit()

## Takes up to `n` from slot `i`. Returns how many were taken.
func take(i: int, n := 1) -> int:
	var s := slots[i]
	if s == null:
		return 0
	n = mini(n, s.count)
	s.count -= n
	if s.count == 0:
		slots[i] = null
	changed.emit()
	return n

## Moves half of the stack in slot `i` into the first empty slot in `order`.
func split(i: int, order: Array = []) -> void:
	var s := slots[i]
	if s == null or s.count < 2:
		return
	for j in (order if not order.is_empty() else range(slots.size())):
		if slots[j] == null:
			move(i, j, int(s.count / 2.0))
			return

## Merges stacks of the same item in slots [from, to) and orders them by ItemData.sort_key().
## Slots outside that range are not touched, so the hotbar layout survives sorting the bag.
func sort_range(from: int, to: int) -> void:
	var totals := {}
	var items: Array[ItemData] = []
	for i in range(from, to):
		var s := slots[i]
		if s:
			if not totals.has(s.item):
				totals[s.item] = 0
				items.append(s.item)
			totals[s.item] += s.count
			slots[i] = null
	items.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.sort_key() < b.sort_key())
	var i := from
	for item in items:
		var left: int = totals[item]
		while left > 0:
			var n := mini(left, item.max_stack)
			slots[i] = ItemStack.new(item, n)
			i += 1
			left -= n
	changed.emit()

func snapshot() -> Array[ItemStack]:
	var out: Array[ItemStack] = []
	for s in slots:
		out.append(s.copy() if s else null)
	return out

func restore(snap: Array[ItemStack]) -> void:
	slots = snap
	changed.emit()
