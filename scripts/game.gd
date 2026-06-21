extends Node2D

@export var level_number := 1

@onready var player = $Player
@onready var parser = CommandParser.new()
@onready var ui = $UI
@onready var coin = $Coin
@onready var goal = $Goal
@onready var executor = CommandExecutor.new()

var command_queue = []
var coins_collected := 0
var level_finished := false
var is_running := false
const FALL_LIMIT_Y = 300
var is_reloading := false

var tutorial_data = {
	1: [
		{"text":"Halo! Aku Byte.", "mood":"idle"},
		{"text":"Coba ketik [color=yellow]move_right(3)[/color]", "mood":"idle"}
	],

	2: [
		{"text":"Sekarang kita belajar repeat()", "mood":"idle"}
	]
}

func _ready():
	setup_ui()
	setup_executor()
	start_tutorial_if_needed()

func _process(delta):
	check_fall_death()

func setup_ui():
	ui.run_pressed.connect(_on_run_pressed)
	ui.restart_pressed.connect(_on_restart_pressed)
	ui.update_objectives(false, false)

func setup_executor():
	add_child(executor)
	executor.setup(player, ui, self)

func start_tutorial_if_needed():
	if tutorial_data.has(level_number):
		ui.start_tutorial(tutorial_data[level_number])

func _on_run_pressed():
	if is_running:
		return

	run_code()

func _on_restart_pressed():
	LevelManager.reload_level()

func run_code():
	ui.clear_error()

	if !parse_user_code():
		return

	await execute_code()

func parse_user_code():

	var code = ui.code_input.text
	command_queue = parser.parse(code)

	if command_queue == null:
		ui.show_error(parser.last_error)
		return false

	return true

func execute_code():
	is_running = true
	await executor.execute_commands(command_queue)
	is_running = false

func post_command_checks():
	await apply_gravity()
	check_hazards()

	if level_finished:
		return

func apply_gravity():
	
	while player.should_fall():
		await player.move_down()

func check_hazards():
	#if player.spike_ahead():
		#await player.die()
		#LevelManager.reload_level()
	check_fall_death()

func check_fall_death():
	if is_reloading:
		return

	if player.global_position.y > FALL_LIMIT_Y:
		is_reloading = true
		await player.die()
		LevelManager.reload_level()

func _on_coin_body_entered(body):
	if body != player:
		return

	collect_coin()

func collect_coin():
	coins_collected += 1
	ui.update_objectives(true, false)
	coin.queue_free()
	AudioManager.play_sfx("coin")

func _on_goal_body_entered(body):

	if body != player:
		return

	if !can_finish_level():
		ui.show_error("Collect coin first!")
		AudioManager.play_error()
		return

	finish_level()

func can_finish_level():
	return coins_collected >= 1

func finish_level():
	level_finished = true
	AudioManager.play_sfx("portal")
	LevelManager.unlock_level(level_number + 1)
	call_deferred("_show_finish_popup")

func _show_finish_popup():
	ui.show_level_complete(level_number)
