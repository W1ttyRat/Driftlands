class_name Highlight
## The white outline on whatever a click would hit or open (Forager-style).

static var _material: ShaderMaterial

static func set_on(node: Node, on: bool) -> void:
	if not _material:
		_material = ShaderMaterial.new()
		_material.shader = load("res://shaders/outline.gdshader")
	for c in node.get_children():
		if c is Sprite2D or c is AnimatedSprite2D:
			c.material = _material if on else null
