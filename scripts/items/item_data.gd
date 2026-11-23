class_name ItemData
extends Resource
## One kind of item (Wood, Stone Axe, ...). Each item is a .tres file in data/items/; edit it in the inspector.

enum Kind { TOOL, BUILDING, RESOURCE }  # also the order "Sort" puts them in

@export var id: StringName
@export var name := ""
@export var icon: Texture2D
@export_multiline var description := ""
@export var kind := Kind.RESOURCE
@export_range(1, 999) var max_stack := 99

@export_group("Tool")
## Matches a Hittable's weak_to ("axe" for trees, "pickaxe" for rocks, "sword" for enemies).
@export var tool_type := ""
## Damage per swing against targets with a matching weak_to. Everything else takes 1.
@export var power := 1

@export_group("Building")
## For kind Building: the scene placed in the world when this item is selected and you click.
@export var building: PackedScene

@export_group("Fuel")
## Seconds one of these burns in a furnace. 0 = not a fuel.
@export_range(0.0, 600.0, 0.1, "suffix:s") var fuel_time := 0.0

func sort_key() -> String:
	return "%d %s" % [kind, name]
