extends CanvasLayer

var counts := {"wood": 0, "stone": 0}

func _ready() -> void:
	add_to_group("hud")
	add("")

func add(kind: String) -> void:
	if counts.has(kind):
		counts[kind] += 1
	$Label.text = "Wood: %d   Stone: %d" % [counts.wood, counts.stone]
