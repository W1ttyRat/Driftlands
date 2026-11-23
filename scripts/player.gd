extends CharacterBody2D

const SPEED := 70.0
const CHEST := Vector2(0, -8)
const REACH := 12.0   # hit box centre, px from the chest
const DIRS := {"right": Vector2.RIGHT, "left": Vector2.LEFT, "down": Vector2.DOWN, "up": Vector2.UP}
const SPRITE_OFFSET := Vector2(-8, -17)
# The attack strips use other frame sizes; these shift them so the head stays over the idle head.
const ATTACK_SHIFT := {"down": Vector2(0, 0), "left": Vector2(-3, 0), "right": Vector2(3, 0), "up": Vector2(-7, -4)}

var facing := "down"
var swinging := false
var want_attack := false
var hovered: Array = []
@onready var sprite: AnimatedSprite2D = $Sprite

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		want_attack = true

func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if not PlayerData.menu_open:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()
	if not swinging:
		if dir != Vector2.ZERO:
			facing = _snap(dir)
		sprite.play(("walk_" if dir != Vector2.ZERO else "idle_") + facing)
	# With a building selected, clicks place it (placer.gd) instead of swinging.
	var held := PlayerData.held()
	var placing := held != null and held.building != null
	_update_hover(placing)
	if want_attack and not swinging and not placing:
		use(_aim())
	want_attack = false

func _snap(v: Vector2) -> String:
	if abs(v.x) > abs(v.y):
		return "right" if v.x > 0 else "left"
	return "down" if v.y > 0 else "up"

func _aim() -> String:
	return _snap(get_global_mouse_position() - (global_position + CHEST))

# Everything a swing in this direction would hit or open.
func _targets(face: String) -> Array:
	var q := PhysicsShapeQueryParameters2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(16, 16)
	q.shape = box
	q.transform = Transform2D(0.0, global_position + CHEST + DIRS[face] * REACH)
	q.exclude = [get_rid()]
	var out := []
	for hit in get_world_2d().direct_space_state.intersect_shape(q):
		if hit.collider.has_method("take_hit") or hit.collider.has_method("interact"):
			out.append(hit.collider)
	return out

func _update_hover(placing := false) -> void:
	var now := [] if placing else _targets(_aim())
	for t in hovered:
		if is_instance_valid(t) and not t in now:
			t.set_hover(false)
	for t in now:
		t.set_hover(true)
	hovered = now

# The tool in the selected hotbar slot does its power against targets weak to it; anything else does 1.
func _damage_to(target: Node) -> int:
	var tool := PlayerData.held()
	if tool and tool.tool_type != "" and tool.tool_type == target.weak_to:
		return tool.power
	return 1

## A click toward `face`: opens a building there (the furnace), otherwise swings.
func use(face: String) -> void:
	for t in _targets(face):
		if t.has_method("interact"):
			t.interact()
			return
	_swing(face)

func _swing(face: String) -> void:
	swinging = true
	facing = face
	for t in _targets(facing):
		if t.has_method("take_hit"):
			t.take_hit(_damage_to(t))
	sprite.offset = SPRITE_OFFSET + ATTACK_SHIFT[facing]
	sprite.play("atk_" + facing)
	await sprite.animation_finished
	sprite.offset = SPRITE_OFFSET
	swinging = false
