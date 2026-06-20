extends Node

@onready var bgm = $BGM
@onready var ui = $UI
@onready var sfx_container = $SFXContainer
@onready var footsteps = $FootstepPlayer

var music_tracks = {}

var sounds = {
	"coin": preload("res://assets/audio/Coin Pickup.wav"),
	"jump": preload("res://assets/audio/Jump.wav"),
	"hurt": preload("res://assets/audio/Hurt.wav"),
	"ui_open": preload("res://assets/audio/UI Open.wav"),
	"ui_close": preload("res://assets/audio/UI Close.wav"),
	
	"run": preload("res://assets/audio/UI Open.wav"),
	"error": preload("res://assets/audio/UI Close.wav"),
	"success": preload("res://assets/audio/Coin Pickup.wav"),
	"portal": preload("res://assets/audio/Victory Theme .mp3")
}

func _ready():
	register_bgm(
		"main_menu",
		preload("res://assets/audio/Chill RPG theme (RPG).wav")
	)

	register_bgm(
		"gameplay",
		preload("res://assets/audio/Basic Rpg Intro Track (RPG).wav")
	)

func register_sound(name, stream):
	sounds[name] = stream

func play_sfx(name):
	if !sounds.has(name):
		push_warning("Sound not found: " + name)
		return

	var player = AudioStreamPlayer.new()
	player.stream = sounds[name]

	sfx_container.add_child(player)
	player.play()

	player.finished.connect(
		func():
			player.queue_free()
	)

func play_ui(name):
	if !sounds.has(name):
		return

	ui.stream = sounds[name]
	ui.play()

func register_bgm(name, stream):
	music_tracks[name] = stream

func play_bgm(name):
	if !music_tracks.has(name):
		return

	var stream = music_tracks[name]

	if bgm.stream == stream and bgm.playing:
		return

	bgm.stream = stream
	bgm.play()

func stop_bgm():
	bgm.stop()
	
func fade_to_bgm(name):
	if !music_tracks.has(name):
		return

	var tween = create_tween()

	tween.tween_property(
		bgm,
		"volume_db",
		-40,
		0.4
	)

	await tween.finished

	bgm.stop()
	bgm.stream = music_tracks[name]
	bgm.play()

	bgm.volume_db = -40

	var tween2 = create_tween()
	tween2.tween_property(
		bgm,
		"volume_db",
		-8,
		0.4
	)
	
func play_run():
	play_sfx("run")
	
func play_error():
	play_sfx("error")
	
func play_success():
	play_sfx("success")

func play_footsteps():
	if !footsteps.playing:
		footsteps.play()

func stop_footsteps():
	footsteps.stop()
