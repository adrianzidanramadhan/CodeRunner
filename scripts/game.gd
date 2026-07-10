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
var total_coins_in_level := 0
var level_finished := false
var is_running := false
const FALL_LIMIT_Y = 300
var is_reloading := false

var tutorial_data = {
	1: [
		{
			"text":"Halo! Namaku Knight. Selamat datang di Code Knight!",
			"mood":"idle"
		},
		{
			"text":"Di game ini, kamu tidak mengendalikan ksatria secara langsung. Kamu akan memberi perintah menggunakan kode",
			"mood":"idle"
		},
		{
			"text":"Coba ketik [color=yellow]move_right()[/color] pada editor di kiri bawah",
			"mood":"idle"
		},
		{
			"text":"Setelah selesai, tekan tombol [color=yellow]Run[/color] untuk menjalankan programmu",
			"mood":"idle"
		},
		{
			"text":"Ambil semua koin, lalu masuk ke portal untuk menyelesaikan level",
			"mood":"idle"
		}
	],

	2: [
		{
			"text":"Bagus! Sekarang kita bisa membuat kode lebih singkat.",
			"mood":"idle"
		},
		{
			"text":"Perintah [color=yellow]move_right()[/color] juga bisa diberi angka.",
			"mood":"idle"
		},
		{
			"text":"Misalnya [color=yellow]move_right(5)[/color] berarti berjalan lima langkah sekaligus.",
			"mood":"idle"
		},
		{
			"text":"Cobalah gunakan parameter agar programmu menjadi lebih ringkas.",
			"mood":"idle"
		}
	],

	3: [
		{
			"text":"Sekarang muncul rintangan baru!",
			"mood":"idle"
		},
		{
			"text":"Gunakan [color=yellow]jump_right()[/color] untuk melompati duri.",
			"mood":"idle"
		},
		{
			"text":"Perhatikan posisi duri sebelum menulis programmu.",
			"mood":"idle"
		}
	],

	4: [
		{
			"text":"Kalau ada banyak gerakan yang sama, jangan menulis berulang-ulang.",
			"mood":"idle"
		},
		{
			"text":"Gunakan [color=cyan]repeat(jumlah):[/color] untuk mengulang beberapa perintah.",
			"mood":"idle"
		},
		{
			"text":"Contoh:\n\n[color=cyan]repeat(3):[/color]\n    [color=yellow]move_right()[/color]",
			"mood":"idle"
		},
		{
			"text":"Loop membuat kode lebih rapi dan lebih mudah dibaca.",
			"mood":"idle"
		}
	],

	5: [
		{
			"text":"Program yang pintar bisa mengambil keputusan sendiri.",
			"mood":"idle"
		},
		{
			"text":"Gunakan [color=cyan]if spike_ahead():[/color] untuk mengecek apakah ada duri di depan.",
			"mood":"idle"
		},
		{
			"text":"Jika ada duri, gunakan [color=yellow]jump_right()[/color]. Jika tidak ada, lanjutkan berjalan.",
			"mood":"idle"
		},
		{
			"text":"Selamat! Kamu sudah mempelajari dasar pemrograman menggunakan percabangan.",
			"mood":"idle"
		}
	],
	
	6: [
		{
			"text":"Hati-hati! Sekarang ada monster yang berpatroli.",
			"mood":"idle"
		},
		{
			"text":"Monster akan berjalan bolak-balik di platformnya.",
			"mood":"idle"
		},
		{
			"text":"Jika kamu memasuki area pandangnya, ia akan mengejarmu.",
			"mood":"idle"
		},
		{
			"text":"Susun programmu dengan baik agar bisa melewati monster dengan aman.",
			"mood":"idle"
		}
	],
	
	7: [
		{
			"text":"Goblin lebih cepat daripada Mushroom!",
			"mood":"idle"
		},
		{
			"text":"Begitu melihatmu, Goblin dapat bergerak dua langkah dalam satu giliran.",
			"mood":"idle"
		},
		{
			"text":"Perhatikan jarakmu sebelum mendekat.",
			"mood":"idle"
		}
	],
	
	8: [
		{
			"text":"Sekarang gunakan semua kemampuan yang sudah kamu pelajari.",
			"mood":"idle"
		},
		{
			"text":"Loop, percabangan, lompatan, dan strategi akan membantumu menyelesaikan level ini.",
			"mood":"idle"
		}
	]
}

func _ready():

	setup_ui()
	setup_executor()

	total_coins_in_level = 0

	for coin in get_tree().get_nodes_in_group("coin"):
		total_coins_in_level += 1
		coin.collected.connect(collect_coin)

	for goal in get_tree().get_nodes_in_group("goal"):
		goal.reached.connect(_on_goal_reached)

	ui.update_objectives(0, total_coins_in_level, false)

	start_tutorial_if_needed()

func _process(delta):
	check_fall_death()

func setup_ui():
	ui.run_pressed.connect(_on_run_pressed)
	ui.restart_pressed.connect(_on_restart_pressed)
	# Tambahkan total_coins_in_level di parameter kedua
	ui.update_objectives(0, total_coins_in_level, false)


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

func enemy_turn():
	var enemies = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if enemy.has_method("take_turn"):
			await enemy.take_turn(player)

func apply_gravity():
	
	while player.should_fall():
		await player.move_down()

func check_hazards():
	check_fall_death()

func check_fall_death():
	if is_reloading:
		return

	if player.global_position.y > FALL_LIMIT_Y:
		is_reloading = true
		await player.die()
		LevelManager.reload_level()

func collect_coin():

	coins_collected += 1

	ui.update_objectives(
		coins_collected,
		total_coins_in_level,
		level_finished
	)

func _on_goal_reached():

	if !can_finish_level():
		ui.show_error("Collect all coins first!")
		AudioManager.play_error()
		return

	finish_level()

func can_finish_level():
	return coins_collected >= total_coins_in_level

func finish_level():
	level_finished = true
	AudioManager.play_sfx("portal")
	LevelManager.unlock_level(level_number + 1)
	
	ui.show_level_complete(level_number, coins_collected, total_coins_in_level)

func _show_finish_popup():
	ui.show_level_complete(level_number)
