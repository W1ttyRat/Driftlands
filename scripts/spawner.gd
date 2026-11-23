extends Node
## Regrows the island, Forager-style: every `interval` seconds, while there are fewer than
## `max_resources` trees, rocks and ore, it puts a random one on a free land cell that is not
## right next to the player.

## Scene tile ids from tileset.tres (Scenes Collection, source 1) -> relative chance.
## 1 = tree, 2 = rock, 3 = iron rock.
@export var weights: Dictionary[int, int] = {1: 45, 2: 35, 3: 20}
@export var interval := 6.0
@export var max_resources := 14

const SOURCE := 1

@onready var world: Node2D = get_parent()
@onready var player: Node2D = world.get_node("Player")

var _time := 0.0

func _process(delta: float) -> void:
	_time += delta
	if _time < interval:
		return
	_time = 0.0
	if world.objects.get_used_cells().size() < max_resources:
		spawn()

## Puts one weighted-random resource on a random free cell. Returns false if no cell was free.
func spawn() -> bool:
	var cells: Array = world.data.get_used_cells().filter(func(c: Vector2i) -> bool:
		return world.is_free(c) and world.cell_center(c).distance_to(player.global_position) > 24.0)
	if cells.is_empty():
		return false
	world.objects.set_cell(cells.pick_random(), SOURCE, Vector2i.ZERO, _pick())
	return true

func _pick() -> int:
	var total := 0
	for w in weights.values():
		total += w
	var roll := randi() % total
	for id in weights:
		roll -= weights[id]
		if roll < 0:
			return id
	return weights.keys()[0]
