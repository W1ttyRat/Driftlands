extends Panel
## One inventory slot on screen, showing PlayerData.inventory slot `index`.
## Drag onto another slot to move or swap, Shift+click to send between hotbar and bag,
## right-click to split the stack in half. Clicking a hotbar slot selects it.

@export var index := 0
## Hotbar slots show their number key and the selection frame.
@export var hotbar := false

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $Count
@onready var key_label: Label = $Key

func _ready() -> void:
	key_label.text = str(index + 1) if hotbar else ""
	PlayerData.inventory.changed.connect(refresh)
	if hotbar:
		PlayerData.selected_changed.connect(_update_selected)
	refresh()
	_update_selected()

func refresh() -> void:
	var s := PlayerData.inventory.get_stack(index)
	icon.texture = s.item.icon if s else null
	count_label.text = str(s.count) if s and s.count > 1 else ""
	tooltip_text = ("%s\n%s" % [s.item.name, s.item.description]).strip_edges() if s else ""

func _update_selected() -> void:
	theme_type_variation = &"SlotSelected" if hotbar and PlayerData.selected == index else &"Slot"

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT and mb.shift_pressed:
		PlayerData.quick_move(index)
		accept_event()
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		PlayerData.split(index)
		accept_event()
	elif mb.button_index == MOUSE_BUTTON_LEFT and hotbar:
		PlayerData.select(index)

func _get_drag_data(_at: Vector2) -> Variant:
	var s := PlayerData.inventory.get_stack(index)
	if s == null:
		return null
	var holder := Control.new()  # the preview's top-left sits at the mouse, so centre the icon on it
	var pic := TextureRect.new()
	pic.texture = s.item.icon
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.size = icon.size
	pic.position = -icon.size / 2
	holder.add_child(pic)
	set_drag_preview(holder)
	return {"slot": index}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("slot")

func _drop_data(_at: Vector2, data: Variant) -> void:
	PlayerData.inventory.move(data.slot, index)
