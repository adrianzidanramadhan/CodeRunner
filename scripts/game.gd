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
		{"text": "Halo! Aku Knight. Selamat datang di petualangan kode!", "mood": "idle"},
		{"text": "Untuk menggerakkan ksatria ke kanan, coba ketik perintah [color=yellow]move_right()[/color] di kotak kiri bawah.", "mood": "idle"},
		{"text": "Setelah mengetik [color=yellow]move_right()[/color], tekan tombol [color=yellow]Run[/color] di atas atau Enter untuk mulai berjalan!", "mood": "idle"}
	],

	2: [
		{"text": "Bagus sekali! Sekarang tantangannya sedikit lebih tinggi.", "mood": "idle"},
		{"text": "Di depan kita ada rintangan baru. Kamu bisa berjalan dengan [color=yellow]move_right()[/color] seperti tadi.", "mood": "idle"},
		{"text": "Tapi jika ada duri atau tebing, gunakan perintah [color=yellow]jump_right()[/color] untuk melompat ke arah kanan!", "mood": "idle"},
		{"text": "Kombinasikan [color=yellow]move_right()[/color] dan [color=yellow]jump_right()[/color] agar ksatria bisa mencapai portal dengan aman.", "mood": "idle"}
	],

	3: [
		{"text": "Lihat, ada lebih banyak duri di jalur ini!", "mood": "idle"},
		{"text": "Menulis [color=yellow]jump_right()[/color] satu per satu cukup melelahkan ya?", "mood": "idle"},
		{"text": "Coba gunakan [color=blue]repeat(jumlah):[/color] lalu tulis perintah di bawahnya dengan indentasi (spasi) agar diulang otomatis.", "mood": "idle"},
		{"text": "Contoh:\n[color=blue]repeat(2):[/color]\n    [color=yellow]move_right()[/color]\n    [color=yellow]jump_right()[/color]", "mood": "idle"},
		{"text": "Susun kombinasi gerakan dan lompatan untuk mengumpulkan semua koin dan mencapai portal!", "mood": "idle"}
	],

	4: [
		{"text": "Kerja bagus sejauh ini! Tapi duri di depan makin rapat.", "mood": "idle"},
		{"text": "Ingat, satu [color=yellow]jump_right()[/color] hanya bisa melompati SATU duri sekaligus.", "mood": "idle"},
		{"text": "Perhatikan jarak antar duri dengan teliti sebelum menulis kodemu.", "mood": "idle"},
		{"text": "Gunakan [color=blue]repeat():[/color] untuk merangkai pola gerak-lompat yang berulang agar kodemu lebih rapi.", "mood": "idle"},
		{"text": "Kumpulkan semua koin di sepanjang jalan, lalu capai portal di ujung level!", "mood": "idle"}
	],

	5: [
		{"text": "Ini level paling menantang sejauh ini, hati-hati!", "mood": "idle"},
		{"text": "Daripada menghitung jarak duri satu per satu, kamu bisa biarkan ksatria 'berpikir' sendiri.", "mood": "idle"},
		{"text": "Coba gunakan [color=blue]if spike_ahead():[/color] lalu [color=yellow]jump_right()[/color], dan [color=blue]else:[/color] lalu [color=yellow]move_right()[/color].", "mood": "idle"},
		{"text": "Dengan begitu, ksatria akan otomatis melompat hanya jika ada duri di depannya!", "mood": "idle"},
		{"text": "Ulangi logika ini dengan [color=blue]repeat(jumlah):[/color] sampai ksatria mencapai portal.", "mood": "idle"},
		{"text": "Selesaikan level ini untuk membuktikan kamu sudah menguasai dasar-dasar pemrograman!", "mood": "idle"}
	]
}

func _ready():
	setup_ui()
	setup_executor()
	
	total_coins_in_level = 0
	for child in get_children():
		if child.name.begins_with("Coin"):
			total_coins_in_level += 1
	print("Total koin yang ditemukan di level ini: ", total_coins_in_level)	
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

func _on_coin_body_entered(body):
	if body != player:
		return

	collect_coin()

func collect_coin():
	coins_collected += 1
	ui.update_objectives(coins_collected, total_coins_in_level, level_finished)
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
	return coins_collected >= total_coins_in_level

func finish_level():
	level_finished = true
	AudioManager.play_sfx("portal")
	LevelManager.unlock_level(level_number + 1)
	
	ui.show_level_complete(level_number, coins_collected, total_coins_in_level)

func _show_finish_popup():
	ui.show_level_complete(level_number)
