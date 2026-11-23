extends GridContainer
## Fills itself with Slot scenes for inventory slots [first, first + count).

const SLOT := preload("res://scenes/ui/slot.tscn")

@export var first := 0
@export var count := 8
@export var hotbar := false

func _ready() -> void:
	for i in range(first, first + count):
		var s := SLOT.instantiate()
		s.index = i
		s.hotbar = hotbar
		add_child(s)
