extends CharacterBody2D

const SPEED := 70.0
const REACH := 12.0   # sword hit box centre, px from the chest
const SWING_TIME := 0.2
const DIRS := {"right": Vector2.RIGHT, "left": Vector2.LEFT, "down": Vector2.DOWN, "up": Vector2.UP}

var facing := "down"
var swinging := false
var want_attack := false
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var sword: Node2D = $Sword

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		want_attack = true

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()
	if dir != Vector2.ZERO and not swinging:
		facing = _snap(dir)
	sprite.play(("walk_" if dir != Vector2.ZERO else "idle_") + facing)
	if want_attack and not swinging:
		_swing()
	want_attack = false

func _snap(v: Vector2) -> String:
	if abs(v.x) > abs(v.y):
		return "right" if v.x > 0 else "left"
	return "down" if v.y > 0 else "up"

func _swing() -> void:
	swinging = true
	facing = _snap(get_global_mouse_position() - (global_position + $Sword.position))
	var dir: Vector2 = DIRS[facing]
	var q := PhysicsShapeQueryParameters2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(16, 16)
	q.shape = box
	q.transform = Transform2D(0.0, sword.global_position + dir * REACH)
	q.exclude = [get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_shape(q):
		if hit.collider.has_method("take_hit"):
			hit.collider.take_hit(1)
	sword.rotation = dir.angle() + PI / 2 - 1.0
	sword.show()
	var t := create_tween()
	t.tween_property(sword, "rotation", dir.angle() + PI / 2 + 1.0, SWING_TIME)
	await t.finished
	sword.hide()
	swinging = false
