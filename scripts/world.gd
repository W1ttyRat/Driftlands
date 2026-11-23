@tool
extends Node2D
# Dual grid: Ground is drawn half a cell off from Data. Each Ground cell picks its tile
# from the 4 Data cells around it (order TL TR BL BR, "1" = land). Paint land in Data.
# shortcut: no tile for the two diagonal-only patterns (1001, 0110), keep island outlines without them.
const TILES := {
	"1111": Vector2i(2, 0), "0000": Vector2i(1, 0),
	"1110": Vector2i(0, 1), "1100": Vector2i(1, 1), "1101": Vector2i(2, 1),
	"1010": Vector2i(0, 2), "0101": Vector2i(2, 2),
	"1011": Vector2i(0, 3), "0011": Vector2i(1, 3), "0111": Vector2i(2, 3),
	"0001": Vector2i(3, 2), "0010": Vector2i(4, 2), "0100": Vector2i(3, 3), "1000": Vector2i(4, 3),
}

@onready var data: TileMapLayer = $Data
@onready var ground: TileMapLayer = $Ground
@onready var objects: TileMapLayer = $Objects
@onready var buildings: Node2D = $Buildings

func _ready() -> void:
	var r := data.get_used_rect().grow(1)
	for y in range(r.position.y, r.end.y + 1):
		for x in range(r.position.x, r.end.x + 1):
			var key := ""
			for c in [Vector2i(x - 1, y - 1), Vector2i(x, y - 1), Vector2i(x - 1, y), Vector2i(x, y)]:
				key += "1" if data.get_cell_source_id(c) != -1 else "0"
			if not TILES.has(key):
				push_warning("No tile for corner pattern %s at %s" % [key, Vector2i(x, y)])
			ground.set_cell(Vector2i(x, y), 0, TILES.get(key, TILES["0000"]))
	if not Engine.is_editor_hint():
		data.hide()
		add_to_group("world")  # machines (the drill) find the grid through this

# --- Grid helpers for placing buildings and regrowing resources (cells of the Data/Objects grid) ---

func cell_at(global_pos: Vector2) -> Vector2i:
	return objects.local_to_map(objects.to_local(global_pos))

## The cell's centre in world space. Buildings and resources stand with their base on it.
func cell_center(cell: Vector2i) -> Vector2:
	return objects.to_global(objects.map_to_local(cell))

func is_land(cell: Vector2i) -> bool:
	return data.get_cell_source_id(cell) != -1

## The tree, rock or iron rock standing on `cell`, or null.
func object_at(cell: Vector2i) -> Node:
	for o in objects.get_children():
		if cell_at(o.global_position) == cell:
			return o
	return null

func building_at(cell: Vector2i) -> Node:
	for b in buildings.get_children():
		if cell_at(b.global_position) == cell:
			return b
	return null

## Land with nothing on it: no tree/rock/ore, no building, and no body (player, enemy) in the way.
func is_free(cell: Vector2i) -> bool:
	if not is_land(cell) or objects.get_cell_source_id(cell) != -1 or building_at(cell):
		return false
	var q := PhysicsShapeQueryParameters2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(14, 14)
	q.shape = box
	q.transform = Transform2D(0.0, cell_center(cell))
	return get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()
