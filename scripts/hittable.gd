extends StaticBody2D
# Anything the sword can hit: tree, rock, skeleton. Dies after `hits` damage and gives `drop` to the player.
@export var hits := 3
@export var drop: ItemData
@export var drop_count := 1
## A held tool with this tool_type does its full power here: "axe", "pickaxe" or "sword".
@export var weak_to := ""

func set_hover(on: bool) -> void:
	Highlight.set_on(self, on)

func take_hit(dmg := 1) -> void:
	if hits <= 0:
		return
	hits -= dmg
	modulate = Color(1, 0.4, 0.4)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)
	if hits > 0:
		return
	if drop:
		PlayerData.give(drop, drop_count)
	var layer := get_parent() as TileMapLayer
	if layer:
		layer.erase_cell(layer.local_to_map(position)) # scene tile: erasing the cell frees the instance
	else:
		queue_free()
