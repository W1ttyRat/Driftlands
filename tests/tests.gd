extends Node
## Automated checks. Run headless from the project folder:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/tests.tscn
## Exit code = number of failed checks. Add `-- --shots=<folder>` (without --headless)
## to also save screenshots of the hotbar, the inventory screen and the crafting screen.

const WOOD := preload("res://data/items/wood.tres")
const STONE := preload("res://data/items/stone.tres")
const AXE := preload("res://data/items/stone_axe.tres")
const SWORD := preload("res://data/items/stone_sword.tres")
const PICK_RECIPE := preload("res://data/recipes/stone_pickaxe.tres")
const AXE_RECIPE := preload("res://data/recipes/stone_axe.tres")

var failures := 0
var checks := 0

func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", what)

func _ready() -> void:
	test_add_and_stack()
	test_remove()
	test_move()
	test_split_transfer_sort()
	test_recipe()
	test_player_data()
	test_crafting_queue()
	await test_world()
	print("%d/%d checks passed" % [checks - failures, checks])
	get_tree().quit(failures)

# --- Inventory --------------------------------------------------------------

func describe(inv: Inventory) -> String:
	var parts := []
	for s in inv.slots:
		parts.append("%s:%d" % [s.item.id, s.count] if s else "-")
	return " ".join(parts)

func test_add_and_stack() -> void:
	var inv := Inventory.new(4)
	check(inv.add(WOOD, 150) == 0 and describe(inv) == "wood:99 wood:51 - -", "add splits into stacks of 99")
	check(inv.add(WOOD, 10) == 0 and describe(inv) == "wood:99 wood:61 - -", "add tops up before using a new slot")
	check(inv.add(AXE, 2) == 0 and describe(inv) == "wood:99 wood:61 stone_axe:1 stone_axe:1", "tools do not stack")
	check(inv.add(STONE, 5) == 5, "a full inventory returns what did not fit")
	var small := Inventory.new(3)
	check(small.add(WOOD, 5, [2, 0]) == 0 and describe(small) == "- - wood:5", "add follows the slot order")

func test_remove() -> void:
	var inv := Inventory.new(3)
	inv.add(WOOD, 5, [0])
	inv.add(WOOD, 5, [2])
	check(inv.remove(WOOD, 7) and describe(inv) == "wood:3 - -", "remove takes from the last slots first")
	check(not inv.remove(WOOD, 4) and describe(inv) == "wood:3 - -", "remove with too few changes nothing")

func test_move() -> void:
	var inv := Inventory.new(4)
	inv.add(WOOD, 98, [0])
	inv.add(WOOD, 5, [1])
	inv.add(STONE, 4, [2])
	inv.move(1, 0)
	check(describe(inv) == "wood:99 wood:4 stone:4 -", "drop on the same item merges what fits")
	inv.move(2, 0)
	check(describe(inv) == "stone:4 wood:4 wood:99 -", "drop on a different item swaps")
	inv.move(0, 3)
	check(describe(inv) == "- wood:4 wood:99 stone:4", "drop on an empty slot moves")
	inv.move(2, 0, 10)
	check(describe(inv) == "wood:10 wood:4 wood:89 stone:4", "moving part of a stack")

func test_split_transfer_sort() -> void:
	var inv := Inventory.new(6)
	inv.add(WOOD, 7, [0])
	inv.split(0, [3, 4])
	check(describe(inv) == "wood:4 - - wood:3 - -", "split moves half to the first empty slot in order")
	inv.add(WOOD, 2, [5])
	inv.transfer(0, [3, 4, 5])
	check(describe(inv) == "- - - wood:7 - wood:2", "transfer tops up the first matching stack in the targets")
	inv.add(STONE, 5, [1])
	inv.add(AXE, 1, [2])
	inv.add(WOOD, 4, [4])
	inv.sort_range(2, 6)
	check(describe(inv) == "- stone:5 stone_axe:1 wood:13 - -", "sort merges and orders tools first, outside the range untouched")

func test_recipe() -> void:
	var inv := Inventory.new(3)
	inv.add(WOOD, 7)
	inv.add(STONE, 5)
	check(AXE_RECIPE.costs(2) == {WOOD: 6, STONE: 4}, "costs scale with the amount")
	check(AXE_RECIPE.max_crafts(inv) == 2, "max_crafts is limited by the scarcest input")
	check(inv.space_for(WOOD) == 92 + 99 and inv.space_for(AXE) == 1, "space_for counts top-ups and empty slots")

func reset_player() -> void:
	var inv := PlayerData.inventory
	for i in inv.size():
		inv.slots[i] = null
	inv.changed.emit()
	PlayerData.select(0)

func test_player_data() -> void:
	reset_player()
	PlayerData.give(WOOD, 3)
	PlayerData.give(AXE)
	check(PlayerData.inventory.get_stack(PlayerData.HOTBAR).item == WOOD, "resources go to the bag first")
	check(PlayerData.inventory.get_stack(0).item == AXE and PlayerData.held() == AXE, "tools go to the hotbar first")
	PlayerData.select(-1)
	check(PlayerData.selected == PlayerData.HOTBAR - 1, "hotbar selection wraps around")
	PlayerData.quick_move(0)
	check(PlayerData.inventory.get_stack(0) == null and PlayerData.inventory.count(AXE) == 1, "shift+click sends a hotbar item to the bag")
	reset_player()

func test_crafting_queue() -> void:
	reset_player()
	PlayerData.give(WOOD, 7)
	PlayerData.give(STONE, 5)
	check(not Crafting.enqueue(AXE_RECIPE, 3), "cannot queue more than you can pay for")
	check(Crafting.enqueue(AXE_RECIPE, 2), "queue 2 axes")
	check(PlayerData.inventory.count(WOOD) == 1 and PlayerData.inventory.count(STONE) == 1, "queuing takes the ingredients straight away")
	Crafting._process(1.0)
	check(PlayerData.inventory.count(AXE) == 0 and Crafting.queue[0].count == 2, "nothing arrives before the craft time")
	Crafting._process(2.1)
	check(PlayerData.inventory.count(AXE) == 1 and Crafting.queue[0].count == 1, "first axe arrives after 3 s")
	Crafting.cancel(0)
	check(Crafting.queue.is_empty() and PlayerData.inventory.count(WOOD) == 4 and PlayerData.inventory.count(STONE) == 3, "cancel refunds the axe not made yet")

	# Full inventory: the job waits instead of losing the item.
	Crafting.enqueue(AXE_RECIPE, 1)
	var inv := PlayerData.inventory
	var free_slot := -1
	for i in inv.size():
		if inv.get_stack(i) == null:
			inv.slots[i] = ItemStack.new(SWORD)
			free_slot = i
	Crafting._process(3.1)
	check(Crafting.queue.size() == 1 and Crafting.queue[0].waiting, "a finished craft waits while the inventory is full")
	inv.slots[free_slot] = null
	Crafting._process(0.0)
	check(Crafting.queue.is_empty() and inv.count(AXE) == 2, "it lands as soon as there is room")
	reset_player()

# --- In the real world scene -----------------------------------------------

func swing(player: Node, face: String) -> void:
	await get_tree().physics_frame
	player._swing(face)
	while player.swinging:
		await get_tree().process_frame

# Stand left of the target so a swing to the right lands on it.
func stand_next_to(player: Node2D, target: Node2D) -> void:
	player.global_position = target.global_position + Vector2(-12, 3)
	await get_tree().physics_frame

func test_world() -> void:
	var world: Node = load("res://scenes/world.tscn").instantiate()
	add_child(world)
	for i in 5:  # scene tiles (trees, rocks) are instanced a frame or two after the layer enters the tree
		await get_tree().physics_frame
	var player: Node2D = world.get_node("Player")
	var hud: CanvasLayer = world.get_node("HUD")
	var trees: Array = world.get_node("Objects").get_children().filter(func(n: Node) -> bool: return n.weak_to == "axe")
	var rocks: Array = world.get_node("Objects").get_children().filter(func(n: Node) -> bool: return n.weak_to == "pickaxe")
	check(trees.size() >= 2 and rocks.size() >= 1, "world has trees and rocks")

	var shots := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots = arg.trim_prefix("--shots=")

	# Bare hands: 3 swings per tree.
	var tree1: Node2D = trees[0]
	await stand_next_to(player, tree1)
	await swing(player, "right")
	await swing(player, "right")
	check(is_instance_valid(tree1) and tree1.hits == 1, "bare hands do 1 damage to a tree")
	await swing(player, "right")
	await get_tree().process_frame
	check(not is_instance_valid(tree1), "tree is gone after 3 bare-hand swings")
	check(PlayerData.inventory.count(WOOD) == 3, "a tree gives 3 wood")

	# Rock for stone.
	var rock: Node2D = rocks[0]
	await stand_next_to(player, rock)
	for i in 3:
		await swing(player, "right")
	check(PlayerData.inventory.count(STONE) == 3, "a rock gives 3 stone")

	# Craft an axe through the crafting screen (Q).
	var screen: Control = hud.get_node("InventoryScreen")
	var crafting: Control = hud.get_node("CraftingScreen")
	Input.parse_input_event(action_event("crafting"))
	await get_tree().process_frame
	check(crafting.visible and not screen.visible and PlayerData.menu_open, "Q opens the crafting screen")
	var start_pos := player.global_position
	Input.action_press("move_right")
	for i in 5:
		await get_tree().physics_frame
	Input.action_release("move_right")
	check(player.global_position == start_pos, "the player stands still while a menu is open")

	var grid: GridContainer = crafting.find_child("Grid", true, false)
	var search: LineEdit = crafting.find_child("Search", true, false)
	check(grid.get_child_count() == 3, "All shows every recipe")
	crafting._categories[Recipe.Category.TOOLS].button_pressed = true
	await get_tree().process_frame
	check(grid.get_child_count() == 2, "Tools shows the axe and the pickaxe")
	search.text = "pick"
	search.text_changed.emit("pick")
	await get_tree().process_frame
	check(grid.get_child_count() == 1 and grid.get_child(0).tooltip_text == "Stone Pickaxe", "search finds the pickaxe")
	search.text = "zzz"
	search.text_changed.emit("zzz")
	await get_tree().process_frame
	check(grid.get_child_count() == 0 and crafting.find_child("NoMatches", true, false).visible, "search with no hits says so")
	crafting._categories[Recipe.Category.WEAPONS].button_pressed = true
	await get_tree().process_frame
	check(search.text == "" and grid.get_child_count() == 1, "picking a category clears the search")

	crafting._categories[Recipe.Category.TOOLS].button_pressed = true
	await get_tree().process_frame
	var axe_tile: Button = crafting._tiles[AXE_RECIPE]
	var pick_tile: Button = crafting._tiles[PICK_RECIPE]
	check(axe_tile.modulate.a == 1.0 and pick_tile.modulate.a == 1.0, "recipes you can afford are bright")
	pick_tile.button_pressed = true
	await get_tree().process_frame
	var craft_button: Button = crafting.find_child("Craft", true, false)
	var table: GridContainer = crafting.find_child("Table", true, false)
	check(crafting.find_child("ItemName", true, false).text == "Stone Pickaxe" and not craft_button.disabled, "picking a tile shows it, Craft is on")
	crafting.find_child("Plus", true, false).pressed.emit()
	check(table.get_child_count() == 12 and (table.get_child(6) as Label).text == "6", "amount 2 doubles the totals")
	check((table.get_child(7) as Label).theme_type_variation == &"Missing" and craft_button.disabled, "missing wood is red and Craft is off")
	axe_tile.button_pressed = true
	await get_tree().process_frame
	check(crafting.find_child("Qty", true, false).text == "1", "picking another recipe resets the amount")
	craft_button.pressed.emit()
	check(Crafting.queue.size() == 1 and PlayerData.inventory.count(WOOD) == 0, "Craft queues the axe and takes the wood")
	check(pick_tile.modulate.a < 1.0, "the pickaxe dims once you cannot afford it")
	await get_tree().process_frame
	var queue_row: HBoxContainer = hud.get_node("CraftQueue")
	check(queue_row.get_child_count() == 1, "the queue shows at the bottom right")
	Input.parse_input_event(action_event("ui_cancel"))
	await get_tree().process_frame
	check(not crafting.visible and not PlayerData.menu_open, "Esc closes the crafting screen")
	Engine.time_scale = 10.0
	while not Crafting.queue.is_empty():
		await get_tree().process_frame
	Engine.time_scale = 1.0
	await get_tree().process_frame
	check(PlayerData.inventory.count(AXE) == 1 and PlayerData.inventory.get_stack(0).item == AXE, "the crafted axe lands in hotbar slot 1")
	check(PlayerData.inventory.count(STONE) == 1 and queue_row.get_child_count() == 0, "crafting used 2 stone and the queue is empty")

	Input.parse_input_event(action_event("inventory"))
	await get_tree().process_frame
	check(screen.visible and not hud.get_node("Hotbar").visible, "Tab opens the inventory and hides the bottom hotbar")
	# Drag the axe from hotbar slot 1 to slot 3 in the screen, then pick it with key 3.
	var slots: Array = screen.find_children("*", "Panel", true, false).filter(func(s: Node) -> bool: return s.hotbar)
	slots[2]._drop_data(Vector2.ZERO, {"slot": 0})
	check(PlayerData.inventory.get_stack(2).item == AXE and PlayerData.inventory.get_stack(0) == null, "drag and drop moves the axe")
	check(slots[2].icon.texture == AXE.icon and slots[0].icon.texture == null, "slots redraw after a move")
	Input.parse_input_event(action_event("inventory"))
	await get_tree().process_frame
	check(not screen.visible, "Tab closes the inventory")
	Input.parse_input_event(action_event("hotbar_3"))
	await get_tree().process_frame
	check(PlayerData.held() == AXE, "key 3 selects the axe")

	# With the axe: 2 swings per tree.
	var tree2: Node2D = trees[1]
	await stand_next_to(player, tree2)
	await swing(player, "right")
	check(is_instance_valid(tree2) and tree2.hits == 1, "the axe does 2 damage to a tree")
	await swing(player, "right")
	await get_tree().process_frame
	check(not is_instance_valid(tree2), "tree is gone after 2 axe swings")

	# The axe is no better than hands against a rock.
	var rock2: Node2D = rocks[1] if rocks.size() > 1 else null
	if rock2:
		await stand_next_to(player, rock2)
		await swing(player, "right")
		check(rock2.hits == 2, "the axe does only 1 damage to a rock")

	if shots != "":
		PlayerData.give(STONE, 40)
		PlayerData.give(SWORD)
		await get_tree().create_timer(0.3).timeout
		await save_shot(shots + "/game.png")
		hud.toggle(screen)
		await get_tree().create_timer(0.1).timeout
		await save_shot(shots + "/inventory.png")
		PlayerData.give(WOOD, 20)
		hud.toggle(crafting)
		crafting._categories[Recipe.Category.TOOLS].button_pressed = true
		crafting._tiles[PICK_RECIPE].button_pressed = true
		Crafting.enqueue(AXE_RECIPE, 2)
		crafting.find_child("Plus", true, false).pressed.emit()
		await get_tree().create_timer(0.2).timeout
		await save_shot(shots + "/crafting.png")

func action_event(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e

func save_shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)
