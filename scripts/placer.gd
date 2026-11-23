extends Node2D
## Building placement. While a building item (kind Building, with a `building` scene) is selected
## in the hotbar, a see-through copy of it follows the mouse, snapped to the grid: green where it
## can go, red where it can't (water, something already there, the player in the way, too far).
## Left click places it and uses up one of the item.

const REACH := 72.0  # px from the player
const OK_TINT := Color(0.6, 1.0, 0.6, 0.75)
const NO_TINT := Color(1.0, 0.35, 0.35, 0.6)

@onready var world: Node2D = get_parent()
@onready var player: Node2D = world.get_node("Player")

var ghost: Node2D
var _ghost_item: ItemData
var cell := Vector2i.ZERO

func _physics_process(_delta: float) -> void:
	var item := PlayerData.held()
	if item == null or item.building == null or PlayerData.menu_open:
		_clear_ghost()
		return
	if item != _ghost_item:
		_make_ghost(item)
	cell = world.cell_at(get_global_mouse_position())
	ghost.global_position = world.cell_center(cell)
	ghost.modulate = OK_TINT if can_place(cell) else NO_TINT

func _unhandled_input(event: InputEvent) -> void:
	if ghost and event.is_action_pressed("attack"):
		place(cell)
		get_viewport().set_input_as_handled()

func can_place(at: Vector2i) -> bool:
	return world.is_free(at) and world.cell_center(at).distance_to(player.global_position) <= REACH

## Places the selected building at `at`. Returns false if it can't go there.
func place(at: Vector2i) -> bool:
	var item := PlayerData.held()
	if item == null or item.building == null or not can_place(at):
		return false
	var b: Building = item.building.instantiate()
	b.item = item
	world.buildings.add_child(b)
	b.global_position = world.cell_center(at)
	PlayerData.inventory.take(PlayerData.selected, 1)
	return true

func _make_ghost(item: ItemData) -> void:
	_clear_ghost()
	ghost = item.building.instantiate()
	ghost.process_mode = Node.PROCESS_MODE_DISABLED  # also takes it out of physics
	ghost.z_index = 1
	add_child(ghost)
	_ghost_item = item

func _clear_ghost() -> void:
	if ghost:
		ghost.queue_free()
	ghost = null
	_ghost_item = null
