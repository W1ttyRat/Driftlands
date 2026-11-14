extends StaticBody2D
# Anything the sword can hit: tree, rock, skeleton. Dies after `hits` hits and pays `drop` to the HUD.
@export var hits := 3
@export var drop := ""

func take_hit(dmg := 1) -> void:
	hits -= dmg
	modulate = Color(1, 0.4, 0.4)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)
	if hits > 0:
		return
	get_tree().call_group("hud", "add", drop)
	var layer := get_parent() as TileMapLayer
	if layer:
		layer.erase_cell(layer.local_to_map(position)) # scene tile: erasing the cell frees the instance
	else:
		queue_free()
