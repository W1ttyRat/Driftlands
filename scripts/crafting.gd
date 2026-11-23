extends Node
## Autoload "Crafting": the recipe list, favourites and the crafting queue.
## Queuing takes the ingredients straight away. Items are made one at a time, each taking the
## recipe's craft_time, and land in the inventory when done. Cancelling a job gives back the
## ingredients for whatever was not made yet, and is refused if they would not fit.
## If the inventory is full when an item finishes, the job waits.

signal queue_changed
signal favorites_changed

const BOOK: RecipeBook = preload("res://data/recipe_book.tres")
const MAX_JOBS := 8

class Job:
	var recipe: Recipe
	var count := 1          # still to make, including the one in progress
	var time_left := 0.0    # of the one in progress
	var waiting := false    # finished, but there is no room in the inventory

var queue: Array[Job] = []
var favorites := {}  # Recipe -> true

func recipes() -> Array[Recipe]:
	return BOOK.recipes

## The recipe at `station` (e.g. "furnace") that takes `item` as its only input, or null.
func recipe_using(item: ItemData, station: String) -> Recipe:
	for r in recipes():
		if r.station == station and r.inputs.size() == 1 and r.inputs.has(item):
			return r
	return null

func can_queue(recipe: Recipe, times: int) -> bool:
	return recipe.by_hand() and times > 0 and queue.size() < MAX_JOBS \
		and PlayerData.inventory.has_all(recipe.costs(times))

func enqueue(recipe: Recipe, times := 1) -> bool:
	if not can_queue(recipe, times):
		return false
	var costs := recipe.costs(times)
	for item in costs:
		PlayerData.inventory.remove(item, costs[item])
	var job := Job.new()
	job.recipe = recipe
	job.count = times
	job.time_left = recipe.craft_time
	queue.append(job)
	queue_changed.emit()
	return true

## Refunds the ingredients and drops the job. Returns false and keeps the job if the refund
## would not all fit in the inventory, so nothing is ever thrown away.
func cancel(i: int) -> bool:
	if i < 0 or i >= queue.size():
		return false
	var job := queue[i]
	var costs := job.recipe.costs(job.count)
	var inv := PlayerData.inventory
	var before := inv.snapshot()
	for item: ItemData in costs:
		if inv.add(item, costs[item], PlayerData.fill_order(item)) > 0:
			inv.restore(before)
			PlayerData.inventory_full.emit(item)
			return false
	queue.remove_at(i)
	for item: ItemData in costs:
		PlayerData.gained.emit(item, costs[item])
	queue_changed.emit()
	return true

func _process(delta: float) -> void:
	if queue.is_empty():
		return
	var job := queue[0]
	job.time_left -= delta
	if job.time_left > 0.0:
		return
	var r := job.recipe
	if PlayerData.inventory.space_for(r.output, PlayerData.fill_order(r.output)) < r.output_count:
		job.time_left = 0.0  # don't bank waiting time towards the next item
		if not job.waiting:
			job.waiting = true
			PlayerData.inventory_full.emit(r.output)
			queue_changed.emit()
		return
	job.waiting = false
	PlayerData.give(r.output, r.output_count)
	job.count -= 1
	job.time_left += r.craft_time  # keep the frame's overshoot so each item takes exactly craft_time
	if job.count == 0:
		queue.pop_front()
	queue_changed.emit()

func is_favorite(r: Recipe) -> bool:
	return favorites.has(r)

func toggle_favorite(r: Recipe) -> void:
	if favorites.has(r):
		favorites.erase(r)
	else:
		favorites[r] = true
	favorites_changed.emit()
