extends CanvasLayer
## Hotbar, pickup messages, crafting queue, and the two menus:
## Tab / I = inventory, Q = crafting. One menu at a time; Esc closes it.

@onready var hotbar: Control = $Hotbar
@onready var toasts: VBoxContainer = $Toasts
@onready var inventory: Control = $InventoryScreen
@onready var crafting: Control = $CraftingScreen

func _ready() -> void:
	inventory.hide()
	crafting.hide()
	PlayerData.gained.connect(func(item: ItemData, n: int) -> void: toast("+%d %s" % [n, item.name]))
	PlayerData.inventory_full.connect(func(_item: ItemData) -> void: toast("Inventory full!"))

# _input, not _unhandled_input: with a menu open the GUI would eat Tab for focus changes.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and PlayerData.menu_open:
		open(null)
	elif get_viewport().gui_get_focus_owner() is LineEdit:
		return  # typing in a search or amount box: letters are text, not hotkeys
	elif event.is_action_pressed("inventory"):
		toggle(inventory)
	elif event.is_action_pressed("crafting"):
		toggle(crafting)
	else:
		return
	get_viewport().set_input_as_handled()

func toggle(menu: Control) -> void:
	open(null if menu.visible else menu)

## Shows `menu` (or nothing) and hides the other one.
func open(menu: Control) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus:
		focus.release_focus()
	inventory.visible = menu == inventory
	crafting.visible = menu == crafting
	hotbar.visible = not inventory.visible  # the inventory screen has its own copy of the hotbar
	PlayerData.menu_open = menu != null

func toast(text: String) -> void:
	var label := Label.new()
	label.text = text
	toasts.add_child(label)
	var tw := label.create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(label.queue_free)
