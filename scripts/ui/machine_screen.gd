extends Control
## Opens when you click a machine (furnace, drill). It asks the machine (see Building) what to
## show: a labelled slot per inventory slot, a progress bar before the last slot (the output), a
## fuel bar under the fuel slot, why it is idle, and some help text. Your bag and hotbar are below.
## Drag between them, or Shift+click to send a stack across (it lands in a slot that takes it).

signal close_requested

const SLOT := preload("res://scenes/ui/slot.tscn")

var machine: Building
## The machine's slots on screen, by slot index.
var machine_slots: Array[Control] = []

var _fuel_bar: ProgressBar
var _progress_bar: ProgressBar

func _ready() -> void:
	%PickUp.pressed.connect(_pick_up)

func open_for(m: Building) -> void:
	machine = m
	for box in [%Machine, %Bag, %Hotbar]:
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
	machine_slots.clear()
	_fuel_bar = null
	%Title.text = m.item.name if m.item else m.name

	var to_player := func(i: int) -> void:
		var s: ItemStack = m.inventory.get_stack(i)
		if s:
			m.inventory.transfer(i, PlayerData.fill_order(s.item), PlayerData.inventory)
	var labels := m.slot_labels()
	_progress_bar = _bar(Vector2(150, 14), &"")
	for i in labels.size():
		if i == labels.size() - 1:
			%Machine.add_child(_progress_bar)
		var col := VBoxContainer.new()
		var label := Label.new()
		label.text = labels[i]
		label.theme_type_variation = &"Header"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(label)
		var holder := HBoxContainer.new()
		holder.alignment = BoxContainer.ALIGNMENT_CENTER
		var slot := _slot(m.inventory, i, false, to_player)
		holder.add_child(slot)
		col.add_child(holder)
		machine_slots.append(slot)
		if i == m.fuel_slot():
			_fuel_bar = _bar(Vector2(56, 8), &"FuelBar")
			col.add_child(_fuel_bar)
		%Machine.add_child(col)

	var to_machine := func(i: int) -> void: PlayerData.inventory.transfer(i, [], m.inventory)
	for i in range(PlayerData.HOTBAR, PlayerData.HOTBAR + PlayerData.BAG):
		%Bag.add_child(_slot(PlayerData.inventory, i, false, to_machine))
	for i in PlayerData.HOTBAR:
		%Hotbar.add_child(_slot(PlayerData.inventory, i, true, to_machine))
	_process(0.0)

func _slot(inv: Inventory, i: int, hotbar: bool, quick: Callable) -> Control:
	var s := SLOT.instantiate()
	s.inventory = inv
	s.index = i
	s.hotbar = hotbar
	s.on_quick_move = quick
	s.on_split = func(_i: int) -> void: pass
	return s

# Colours come from theme.tres: ProgressBar (job progress) and its FuelBar variation.
func _bar(min_size: Vector2, variation: StringName) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = min_size
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.max_value = 1.0
	b.step = 0.0
	b.show_percentage = false
	b.theme_type_variation = variation
	return b

func _process(_delta: float) -> void:
	if not visible or machine == null:
		return
	if not is_instance_valid(machine):
		close_requested.emit()
		return
	_progress_bar.value = machine.progress()
	if _fuel_bar:
		_fuel_bar.value = machine.fuel_left()
	var why := machine.status()
	%Status.text = machine.working_text() if why == "" else why
	%Status.theme_type_variation = &"" if why == "" else &"Hint"
	%Info.text = machine.info()

func _pick_up() -> void:
	if machine.pick_up():
		close_requested.emit()
