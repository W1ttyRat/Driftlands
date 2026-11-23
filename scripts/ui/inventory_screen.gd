extends Control
## The Tab/I screen: bag and hotbar. Crafting has its own screen (Q). The full-screen dimmer
## catches clicks, so the player does not swing while it is open.

func _ready() -> void:
	%Sort.pressed.connect(PlayerData.sort_bag)
