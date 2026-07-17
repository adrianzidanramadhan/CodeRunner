extends Node

signal hp_changed(current_hp, max_hp)
signal player_died

@export var max_hp := 5
var current_hp := 5

func _ready():
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)

func take_damage(amount := 1):

	current_hp -= amount

	if current_hp < 0:
		current_hp = 0

	hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		player_died.emit()

func heal(amount := 1):

	current_hp += amount

	if current_hp > max_hp:
		current_hp = max_hp

	hp_changed.emit(current_hp, max_hp)

func reset_hp():

	current_hp = max_hp

	hp_changed.emit(current_hp, max_hp)
