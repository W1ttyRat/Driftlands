extends Building
## Mines a rock or iron rock on a cell next to it (right, down, left, up) without using it up:
## one of the rock's drop every `mine_time` seconds. Each piece goes into a machine next to the
## drill that takes it (iron ore into a furnace's smelt slot); otherwise it stays in the drill.
## Rocks are the hittables that are weak to the pickaxe.

const OUTPUT := 0
const SIDES: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

@export var mine_time := 6.0

var target: Node     # the rock it is mining, or null
var elapsed := 0.0   # seconds into the current piece

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var world: Node = get_tree().get_first_node_in_group("world")

func _init() -> void:
	inventory = Inventory.new(1)
	inventory.filters = {OUTPUT: func(_it: ItemData) -> bool: return false}  # nothing goes in from outside

func is_working() -> bool:
	return sprite.animation == &"on"

func _process(delta: float) -> void:
	if not _next_to_me(target):
		target = _find_rock()  # the old one is gone or was never there
		elapsed = 0.0
	if target == null or _destination(target.drop) == null:
		sprite.play(&"off")
		return
	sprite.play(&"on")
	elapsed += delta
	if elapsed >= mine_time:
		elapsed -= mine_time
		_deliver(target.drop)

func _cell() -> Vector2i:
	return world.cell_at(global_position)

# Untyped: `node` may be a rock that was mined away (freed).
func _next_to_me(node: Variant) -> bool:
	return is_instance_valid(node) and world.cell_at(node.global_position) - _cell() in SIDES

func _find_rock() -> Node:
	if world == null:
		return null
	for side in SIDES:
		var o: Node = world.object_at(_cell() + side)
		if o and o.get("weak_to") == "pickaxe" and o.get("drop"):
			return o
	return null

## Machines next to the drill that would take `item`, in SIDES order.
func _takers(item: ItemData) -> Array[Building]:
	var out: Array[Building] = []
	for side in SIDES:
		var b: Building = world.building_at(_cell() + side)
		if b and b != self and b.inventory and b.inventory.space_for(item) > 0:
			out.append(b)
	return out

## Where the next piece goes: a machine next to it, the drill itself, or null when all are full.
func _destination(item: ItemData) -> Object:
	var takers := _takers(item)
	if not takers.is_empty():
		return takers[0]
	var own := inventory.get_stack(OUTPUT)
	if own == null or (own.item == item and own.count < item.max_stack):
		return self
	return null

func _deliver(item: ItemData) -> void:
	var to := _destination(item)
	if to is Building and to != self:
		to.inventory.add(item, 1)
		return
	var own := inventory.get_stack(OUTPUT)
	if own:
		own.count += 1
	else:
		inventory.slots[OUTPUT] = ItemStack.new(item, 1)
	inventory.changed.emit()

# --- Machine screen ---

func slot_labels() -> Array[String]:
	return ["Output"]

func progress() -> float:
	return elapsed / mine_time if is_instance_valid(target) else 0.0

func status() -> String:
	if not _next_to_me(target):
		return "Place it next to a rock or an iron rock."
	if _destination(target.drop) == null:
		return "Output is full."
	return ""

func working_text() -> String:
	return "Mining %s..." % target.drop.name if is_instance_valid(target) else ""

func info() -> String:
	var lines := ["1 piece every %ss from the rock next to it; the rock is not used up." % str(mine_time)]
	if is_instance_valid(target):
		var takers := _takers(target.drop)
		if takers.is_empty():
			lines.append("Keeps it here. Put a furnace next to the drill to smelt iron ore automatically.")
		else:
			lines.append("Sends it into the %s next to it." % (takers[0].item.name if takers[0].item else "machine"))
	return "\n".join(lines)
