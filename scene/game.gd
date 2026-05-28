extends Node2D

@onready var code_input = $UI/CodeInput
@onready var player = $Player

var command_queue = []

func move_player_multiple(times):
	for i in range(times):
		await move_once()

func move_once():
	player.move_right()

	while player.is_moving:
		await get_tree().process_frame


func _on_run_button_pressed():
	command_queue.clear()

	var code = code_input.text
	parse_code(code)

	await execute_commands()
	

func parse_code(code):

	var lines = code.split("\n")

	var i = 0

	while i < lines.size():

		var line = lines[i].strip_edges()

		# =========================
		# REPEAT
		# =========================
		if line.begins_with("repeat"):

			var start = line.find("(")
			var end = line.find(")")

			var number_text = line.substr(start + 1, end - start - 1)

			var repeat_amount = int(number_text)

			i += 1

			if i >= lines.size():
				return

			var repeated_line = lines[i].strip_edges()

			for r in range(repeat_amount):

				parse_single_command(repeated_line)

		else:
			parse_single_command(line)

		i += 1

func parse_single_command(line):

	if line.begins_with("jump_right"):
		command_queue.append("jump_right")

	elif line.begins_with("jump_left"):
		command_queue.append("jump_left")

	elif line.begins_with("jump"):
		command_queue.append("jump")

	elif line.begins_with("move_right"):
		parse_move(line, "right")

	elif line.begins_with("move_left"):
		parse_move(line, "left")

func parse_move(line, direction):

	var start = line.find("(")
	var end = line.find(")")

	if start == -1 or end == -1:
		return

	var number_text = line.substr(start + 1, end - start - 1)

	var amount = 1

	if number_text.strip_edges() != "":
		amount = int(number_text)

	for i in range(amount):
		command_queue.append(direction)


func execute_commands():

	for i in range(command_queue.size()):

		update_queue_display(i)

		var command = command_queue[i]

		match command:

			"right":
				var success = player.move_right()

				if not success:
					show_error("Movement blocked!")
					return

			"left":
				var success = player.move_left()

				if not success:
					show_error("Movement blocked!")
					return

			"jump":

				var success = player.move_up()

				if not success:
					show_error("Jump blocked!")
					return

				while player.is_moving:
					await get_tree().process_frame

				success = player.move_up()

				if not success:
					player.is_jumping = false
				else:
					while player.is_moving:
						await get_tree().process_frame

				player.is_jumping = false
			
			"jump_right":

				player.is_jumping = true

				var success = player.move_up()

				if not success:
					show_error("Jump blocked!")
					return

				while player.is_moving:
					await get_tree().process_frame

				success = player.move_right()

				if not success:
					player.is_jumping = false
					show_error("Can't move in air!")
					return

				while player.is_moving:
					await get_tree().process_frame

				player.is_jumping = false
				
			"jump_left":

				player.is_jumping = true

				var success = player.move_up()

				if not success:
					show_error("Jump blocked!")
					return

				while player.is_moving:
					await get_tree().process_frame

				success = player.move_left()

				if not success:
					player.is_jumping = false
					show_error("Can't move in air!")
					return

				while player.is_moving:
					await get_tree().process_frame

				player.is_jumping = false

		while player.is_moving:
			await get_tree().process_frame

		while player.should_fall() and !player.is_jumping:

			player.move_down()

			while player.is_moving:
				await get_tree().process_frame

	update_queue_display()


func _on_goal_body_entered(body):

	if body.name == "Player":
		print("LEVEL COMPLETE!")

@onready var queue_display = $UI/QueueDisplay

func update_queue_display(current_index = -1):

	queue_display.text = ""

	for i in range(command_queue.size()):

		if i == current_index:
			queue_display.text += "[color=yellow]▶ " + command_queue[i] + "[/color]\n"
		else:
			queue_display.text += command_queue[i] + "\n"

@onready var error_label = $UI/ErrorLabel

func show_error(message):

	error_label.text = message

	await get_tree().create_timer(2.0).timeout

	error_label.text = ""
