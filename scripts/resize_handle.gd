extends Control

@onready var code_input = get_parent()

@export var min_height: float = 100.0
@export var max_height: float = 480.0

@export var default_height: float = 240.0
@export var maximized_height: float = 480.0

var dragging: bool = false
var is_maximized: bool = false

var initial_mouse_y: float = 0.0
var initial_height: float = 0.0

func _ready():
	if has_node("ExpandButton"):
		$ExpandButton.pressed.connect(_on_expand_button_pressed)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if dragging:
				initial_mouse_y = get_global_mouse_position().y
				initial_height = code_input.custom_minimum_size.y

	if event is InputEventMouseMotion and dragging:
		var current_mouse_y = get_global_mouse_position().y
		var delta_y = initial_mouse_y - current_mouse_y
		
		var new_height = clamp(initial_height + delta_y, min_height, max_height)
		
		code_input.custom_minimum_size.y = new_height

func _on_expand_button_pressed():
	var target_height = maximized_height if not is_maximized else default_height
	is_maximized = not is_maximized
	
	if has_node("ExpandButton"):
		$ExpandButton.text = "▼" if is_maximized else "▲"
	
	var tween = create_tween()
	tween.tween_property(code_input, "custom_minimum_size:y", target_height, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
