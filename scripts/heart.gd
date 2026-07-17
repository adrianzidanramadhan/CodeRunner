extends Control

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_full := true
var is_playing := false
var idle_bounce_running := false
var start_position : Vector2


func _ready():
	start_position = position
	play_idle_bounce()


func set_full():
	is_full = true
	sprite.play("full")


func set_empty():
	is_full = false
	sprite.play("empty")


func play_damage():

	if is_playing:
		return

	is_playing = true
	is_full = false

	sprite.play("damage")

	await sprite.animation_finished

	sprite.play("empty")

	is_playing = false


func play_heal():

	if is_playing:
		return

	is_playing = true
	is_full = true

	sprite.play("heal")

	await sprite.animation_finished

	sprite.play("full")

	is_playing = false


func play_shine():

	if !is_full:
		return

	if is_playing:
		return

	is_playing = true

	sprite.play("shine")

	await sprite.animation_finished

	sprite.play("full")

	is_playing = false


func play_idle_bounce():
	if is_playing:
		return

	var tween = create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2(1.08,1.08),
		0.08
	)

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.10
	)
