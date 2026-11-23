extends Node
## Autoload "Crafting": the recipe list, favourites and the crafting queue.
## Queuing takes the ingredients straight away. Items are made one at a time, each taking the
## recipe's craft_time, and land in the inventory when done. Cancelling a job gives back the
## ingredients for whatever was not made yet. If the inventory is full the job waits.

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

func cancel(i: int) -> void:
	if i < 0 or i >= queue.size():
		return
	var job := queue[i]
	queue.remove_at(i)
	var costs := job.recipe.costs(job.count)
	for item in costs:
		PlayerData.give(item, costs[item])
	queue_changed.emit()

func _process(delta: float) -> void:
	if queue.is_empty():
		return
	var job := queue[0]
	job.time_left -= delta
	if job.time_left > 0.0:
		return
	var r := job.recipe
	if PlayerData.inventory.space_for(r.output, PlayerData.fill_order(r.output)) < r.output_count:
		if not job.waiting:
			job.waiting = true
			PlayerData.inventory_full.emit(r.output)
			queue_changed.emit()
		return
	job.waiting = false
	PlayerData.give(r.output, r.output_count)
	job.count -= 1
	job.time_left = r.craft_time
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
