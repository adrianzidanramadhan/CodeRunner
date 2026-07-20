extends Control

@export var coin_label: Label 

var banner_start_pos : Vector2
var idle_time := 0.0
var next_level = 1

func _ready():
	visible = false

func set_coin_text(coins_collected: int, total_coins: int):
	if coin_label:
		coin_label.text = "Coin: " + str(coins_collected) + "/" + str(total_coins)
	else:
		push_error("CoinLabel belum dihubungkan di Inspector!")

func show_popup(level_number):
	next_level = min(level_number + 1, LevelManager.MAX_LEVEL)
	visible = true
	idle_time = 0

func _on_next_button_pressed():
	LevelManager.load_level(next_level)

func _on_level_select_button_pressed():
	LevelManager.open_level_select = true
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
