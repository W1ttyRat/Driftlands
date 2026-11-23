extends Control
## The Q screen. Left: categories. Middle: the recipes in that category (or matching the search,
## across all categories). Right: the picked recipe with its ingredient table, quantity and Craft.
## Recipes you cannot afford right now are dimmed.

const ALL := -1
const FAVORITES := -2

var category := ALL
var selected: Recipe
var qty := 1

var _tiles := {}        # Recipe -> Button
var _categories := {}   # category id -> Button

func _ready() -> void:
	var group := ButtonGroup.new()
	for c in [ALL, FAVORITES] + Recipe.Category.values():
		var b := Button.new()
		b.theme_type_variation = &"Category"
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.toggled.connect(func(on: bool) -> void: if on: _pick_category(c))
		var n := Label.new()
		n.theme_type_variation = &"Hint"
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
		b.add_child(n)
		%Categories.add_child(b)
		_categories[c] = b
	_categories[ALL].button_pressed = true

	%Search.text_changed.connect(func(_t: String) -> void: _build_grid())
	%Search.text_submitted.connect(func(_t: String) -> void: %Search.release_focus())
	%Minus.pressed.connect(func() -> void: _set_qty(qty - 1))
	%Plus.pressed.connect(func() -> void: _set_qty(qty + 1))
	%Qty.text_submitted.connect(func(t: String) -> void: _set_qty(int(t)); %Qty.release_focus())
	%Qty.focus_exited.connect(func() -> void: _set_qty(int(%Qty.text)))
	%Craft.pressed.connect(func() -> void: Crafting.enqueue(selected, qty))
	%Favorite.pressed.connect(func() -> void: Crafting.toggle_favorite(selected))

	PlayerData.inventory.changed.connect(_refresh)
	Crafting.queue_changed.connect(_refresh)
	Crafting.favorites_changed.connect(_build_grid)
	visibility_changed.connect(func() -> void: if visible: _build_grid())
	_build_grid()

func _name_of(c: int) -> String:
	match c:
		ALL: return "All"
		FAVORITES: return "Favorites"
	return Recipe.category_name(c)

func _in_category(r: Recipe, c: int) -> bool:
	return c == ALL or (c == FAVORITES and Crafting.is_favorite(r)) or r.category == c

func _pick_category(c: int) -> void:
	category = c
	%Search.text = ""
	_build_grid()

func _shown() -> Array[Recipe]:
	var q: String = %Search.text.strip_edges().to_lower()
	if q != "":
		return Crafting.recipes().filter(func(r: Recipe) -> bool: return r.output.name.to_lower().contains(q))
	return Crafting.recipes().filter(func(r: Recipe) -> bool: return _in_category(r, category))

func _build_grid() -> void:
	for t in %Grid.get_children():
		%Grid.remove_child(t)
		t.queue_free()
	_tiles.clear()
	var group := ButtonGroup.new()
	for r in _shown():
		var t := Button.new()
		t.theme_type_variation = &"Tile"
		t.custom_minimum_size = Vector2(64, 64)
		t.toggle_mode = true
		t.button_group = group
		t.focus_mode = Control.FOCUS_NONE
		t.icon = r.output.icon
		t.expand_icon = true
		t.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.tooltip_text = r.output.name
		t.button_pressed = r == selected
		t.toggled.connect(func(on: bool) -> void: if on: _select(r))
		%Grid.add_child(t)
		_tiles[r] = t
	%NoMatches.visible = _tiles.is_empty()
	%NoMatches.text = "Nothing matches." if %Search.text.strip_edges() != "" else "Nothing here yet."
	for c in _categories:
		var n: int = Crafting.recipes().filter(func(r: Recipe) -> bool: return _in_category(r, c)).size()
		var b: Button = _categories[c]
		b.text = _name_of(c)
		(b.get_child(0) as Label).text = str(n)
		b.modulate.a = 1.0 if n > 0 or c == FAVORITES else 0.45
	_refresh()

func _select(r: Recipe) -> void:
	selected = r
	qty = 1
	_refresh()

func _set_qty(n: int) -> void:
	qty = clampi(n, 1, 999)
	_refresh()

func _refresh() -> void:
	var inv := PlayerData.inventory
	for r: Recipe in _tiles:
		_tiles[r].modulate = Color.WHITE if r.by_hand() and r.max_crafts(inv) > 0 else Color(1, 1, 1, 0.4)
	%Empty.visible = selected == null
	%Info.visible = selected != null
	if selected == null:
		return
	var r := selected
	%BigIcon.texture = r.output.icon
	%ItemName.text = r.output.name + (" x%d" % r.output_count if r.output_count > 1 else "")
	%Description.text = r.output.description
	%Time.text = "Craft time: %ss each" % str(snappedf(r.craft_time, 0.1))
	%Requires.visible = not r.by_hand()
	%Requires.text = "Needs a %s" % r.station.capitalize()
	%Favorite.text = "Unfavorite" if Crafting.is_favorite(r) else "Favorite"
	%Qty.text = str(qty)
	_fill_table(r, inv)
	%Craft.disabled = not Crafting.can_queue(r, qty)
	%Craft.tooltip_text = "Queue is full" if Crafting.queue.size() >= Crafting.MAX_JOBS else ""

func _fill_table(r: Recipe, inv: Inventory) -> void:
	for c in %Table.get_children():
		%Table.remove_child(c)
		c.queue_free()
	for h in ["Amount", "Item", "Total", "Have"]:
		%Table.add_child(_cell(h, &"Header"))
	for item: ItemData in r.inputs:
		var need: int = r.inputs[item]
		var have := inv.count(item)
		%Table.add_child(_cell(str(need)))
		var name_box := HBoxContainer.new()
		name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pic := TextureRect.new()
		pic.texture = item.icon
		pic.custom_minimum_size = Vector2(32, 32)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		name_box.add_child(pic)
		name_box.add_child(_cell(item.name))
		%Table.add_child(name_box)
		%Table.add_child(_cell(str(need * qty)))
		%Table.add_child(_cell(str(have), &"" if have >= need * qty else &"Missing"))

func _cell(text: String, variation := &"") -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l
