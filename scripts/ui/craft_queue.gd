extends HBoxContainer
## Bottom-right row of queued crafts: icon, how many are left, and the countdown on the first one.
## Click one to cancel it and get its ingredients back.

var _timer: Label

func _ready() -> void:
	Crafting.queue_changed.connect(_rebuild)
	_rebuild()

func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_timer = null
	for i in Crafting.queue.size():
		var job: Crafting.Job = Crafting.queue[i]
		var b := Button.new()
		b.theme_type_variation = &"Tile"
		b.custom_minimum_size = Vector2(56, 56)
		b.focus_mode = Control.FOCUS_NONE
		b.icon = job.recipe.output.icon
		b.expand_icon = true
		b.tooltip_text = "%s x%d\nClick to cancel" % [job.recipe.output.name, job.count]
		b.pressed.connect(Crafting.cancel.bind(i))
		if job.count > 1:
			b.add_child(_corner_label(str(job.count), HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_BOTTOM))
		if i == 0:
			_timer = _corner_label("", HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP)
			_timer.position.y -= 26
			b.add_child(_timer)
		add_child(b)
	_process(0.0)

func _corner_label(text: String, h: HorizontalAlignment, v: VerticalAlignment) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = h
	l.vertical_alignment = v
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 3)
	return l

func _process(_delta: float) -> void:
	if _timer and not Crafting.queue.is_empty():
		var job: Crafting.Job = Crafting.queue[0]
		_timer.text = "Full" if job.waiting else "%ds" % ceili(maxf(job.time_left, 0.0))
