extends Panel
## One inventory slot on screen, showing slot `index` of `inventory` (default: the player's).
## Drag onto another slot to move or swap (also between inventories, e.g. into a furnace),
## Shift+click to quick-move, right-click to split the stack in half. Clicking a hotbar slot selects it.

@export var index := 0
## Hotbar slots show their number key and the selection frame.
@export var hotbar := false
## Set before adding to the tree. null = PlayerData.inventory.
var inventory: Inventory
## Shift+click and right-click actions, called with `index`. Default: the player's hotbar <-> bag
## and split. Screens like the furnace's swap in their own.
var on_quick_move: Callable
var on_split: Callable

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $Count
@onready var key_label: Label = $Key

func _ready() -> void:
	if inventory == null:
		inventory = PlayerData.inventory
	if not on_quick_move.is_valid():
		on_quick_move = PlayerData.quick_move
	if not on_split.is_valid():
		on_split = PlayerData.split
	key_label.text = str(index + 1) if hotbar else ""
	inventory.changed.connect(refresh)
	if hotbar:
		PlayerData.selected_changed.connect(_update_selected)
	refresh()
	_update_selected()

func refresh() -> void:
	var s := inventory.get_stack(index)
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
		on_quick_move.call(index)
		accept_event()
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		on_split.call(index)
		accept_event()
	elif mb.button_index == MOUSE_BUTTON_LEFT and hotbar:
		PlayerData.select(index)

func _get_drag_data(_at: Vector2) -> Variant:
	var s := inventory.get_stack(index)
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
	return {"inv": inventory, "slot": index}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("inv")):
		return false
	var s: ItemStack = data.inv.get_stack(data.slot)
	return s != null and inventory.accepts(index, s.item)

func _drop_data(_at: Vector2, data: Variant) -> void:
	data.inv.move_to(data.slot, inventory, index)
