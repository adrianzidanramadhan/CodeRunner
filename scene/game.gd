extends Node2D

@onready var code_input = $UI/CodeInput
@onready var player = $Player

@onready var queue_display = $UI/QueueDisplay
@onready var error_label = $UI/ErrorLabel

var command_queue = []

var coins_collected = 0


# ==================================================
# RUN
# ==================================================

func _on_run_button_pressed():

	command_queue.clear()

	var code = code_input.text

	parse_code(code)

	print(command_queue)

	await execute_commands()


# ==================================================
# PARSER
# ==================================================

func parse_code(code):

	var lines = code.split("\n")

	var i = 0

	while i < lines.size():

		var line = lines[i].strip_edges()

		# ==========================================
		# REPEAT
		# ==========================================
		if line.begins_with("repeat"):

			var start = line.find("(")
			var end = line.find(")")

			var number_text = line.substr(start + 1, end - start - 1)

			var repeat_amount = int(number_text)

			var repeat_indent = get_indent(lines[i])

			# ======================================
			# PARSE CHILD BLOCK
			# ======================================
			var result = parse_block(
				lines,
				i + 1,
				repeat_indent
			)

			var repeat_commands = result["commands"]

			i = result["next_index"] - 1

			# ======================================
			# DUPLICATE COMMANDS
			# ======================================
			for r in range(repeat_amount):

				for cmd in repeat_commands:

					command_queue.append(cmd)

		# ==========================================
		# IF
		# ==========================================
		elif line.begins_with("if"):

			var condition = ""

			if line.contains("wall_right()"):
				condition = "wall_right"

			elif line.contains("spike_ahead()"):
				condition = "spike_ahead"

			# ======================================
			# TRUE COMMAND
			# ======================================
			i += 1

			if i >= lines.size():
				return

			var true_line = lines[i].strip_edges()

			var true_command = parse_command_data(true_line)

			# ======================================
			# FALSE COMMAND
			# ======================================
			var false_command = null

			if i + 1 < lines.size():

				var else_line = lines[i + 1].strip_edges()

				if else_line.begins_with("else"):

					i += 2

					if i < lines.size():

						var false_line = lines[i].strip_edges()

						false_command = parse_command_data(false_line)

			# ======================================
			# SAVE IF OBJECT
			# ======================================
			command_queue.append({

				"type": "if",

				"condition": condition,

				"true_command": true_command,

				"false_command": false_command
			})

		else:
			parse_single_command(line)

		i += 1


# ==================================================
# PARSE SINGLE COMMAND
# ==================================================

func parse_single_command(line):

	var command_data = parse_command_data(line)

	if command_data != null:
		command_queue.append(command_data)


# ==================================================
# COMMAND DATA
# ==================================================

func parse_command_data(line):

	# ==========================================
	# MOVE RIGHT
	# ==========================================
	if line.begins_with("move_right"):

		return {
			"type": "move",
			"direction": "right",
			"amount": get_amount(line)
		}

	# ==========================================
	# MOVE LEFT
	# ==========================================
	elif line.begins_with("move_left"):

		return {
			"type": "move",
			"direction": "left",
			"amount": get_amount(line)
		}

	# ==========================================
	# JUMP
	# ==========================================
	elif line.begins_with("jump_right"):

		return {
			"type": "jump_right"
		}

	elif line.begins_with("jump_left"):

		return {
			"type": "jump_left"
		}

	elif line.begins_with("jump"):

		return {
			"type": "jump"
		}

	return null


# ==================================================
# GET AMOUNT
# ==================================================

func get_amount(line):

	var start = line.find("(")
	var end = line.find(")")

	if start == -1 or end == -1:
		return 1

	var number_text = line.substr(start + 1, end - start - 1)

	if number_text.strip_edges() == "":
		return 1

	return int(number_text)

func get_indent(line):

	var count = 0

	for char in line:

		if char == " ":
			count += 1
		else:
			break

	return count


func parse_block(lines, start_index, parent_indent):

	var commands = []

	var i = start_index

	while i < lines.size():

		var raw_line = lines[i]

		# skip empty
		if raw_line.strip_edges() == "":
			i += 1
			continue

		var indent = get_indent(raw_line)

		# keluar block
		if indent <= parent_indent:
			break

		var line = raw_line.strip_edges()

		# ======================================
		# IF
		# ======================================
		if line.begins_with("if"):

			var condition = ""

			if line.contains("wall_right()"):
				condition = "wall_right"

			elif line.contains("spike_ahead()"):
				condition = "spike_ahead"

			# TRUE COMMAND
			i += 1

			var true_line = lines[i].strip_edges()

			var true_command = parse_command_data(true_line)

			# FALSE COMMAND
			var false_command = null

			if i + 1 < lines.size():

				var else_line = lines[i + 1].strip_edges()

				if else_line.begins_with("else"):

					i += 2

					if i < lines.size():

						false_command = parse_command_data(
							lines[i].strip_edges()
						)

			commands.append({

				"type": "if",

				"condition": condition,

				"true_command": true_command,

				"false_command": false_command
			})

		# ======================================
		# NORMAL COMMAND
		# ======================================
		else:

			var command_data = parse_command_data(line)

			if command_data != null:
				commands.append(command_data)

		i += 1

	return {
		"commands": commands,
		"next_index": i
	}


# ==================================================
# EXECUTOR
# ==================================================

func execute_commands():

	for i in range(command_queue.size()):

		update_queue_display(i)

		var command = command_queue[i]

		await execute_command(command)

	update_queue_display()


# ==================================================
# EXECUTE SINGLE COMMAND
# ==================================================

func execute_command(command):

	var type = command["type"]

	match type:

		# ======================================
		# MOVE
		# ======================================
		"move":

			var direction = command["direction"]
			var amount = command["amount"]

			for step in range(amount):

				var success = false

				if direction == "right":
					success = player.move_right()

				elif direction == "left":
					success = player.move_left()

				if not success:
					show_error("Movement blocked!")
					return

				await wait_for_player()

		# ======================================
		# JUMP
		# ======================================
		"jump":

			await perform_jump()

		# ======================================
		# JUMP RIGHT
		# ======================================
		"jump_right":

			await perform_jump_right()

		# ======================================
		# JUMP LEFT
		# ======================================
		"jump_left":

			await perform_jump_left()

		# ======================================
		# IF
		# ======================================
		"if":

			var condition = command["condition"]

			var condition_result = false

			match condition:

				"wall_right":
					condition_result = player.wall_on_right()

				"spike_ahead":
					condition_result = player.spike_ahead()

			# ======================================
			# TRUE
			# ======================================
			if condition_result:

				var true_command = command["true_command"]

				if true_command != null:
					await execute_command(true_command)

			# ======================================
			# FALSE
			# ======================================
			else:

				var false_command = command["false_command"]

				if false_command != null:
					await execute_command(false_command)

	# ==========================================
	# APPLY GRAVITY
	# ==========================================
	while player.should_fall() and !player.is_jumping:

		player.move_down()

		while player.is_moving:
			await get_tree().process_frame


# ==================================================
# WAIT PLAYER
# ==================================================

func wait_for_player():

	while player.is_moving:
		await get_tree().process_frame


# ==================================================
# JUMP FUNCTIONS
# ==================================================

func perform_jump():

	player.is_jumping = true

	var success = player.move_up()

	if not success:
		show_error("Jump blocked!")
		return

	await wait_for_player()

	success = player.move_up()

	if success:
		await wait_for_player()

	player.is_jumping = false


func perform_jump_right():

	player.is_jumping = true

	var success = player.move_up()

	if not success:
		show_error("Jump blocked!")
		return

	await wait_for_player()

	success = player.move_up()

	if success:
		await wait_for_player()

	success = player.move_right()

	if not success:
		player.is_jumping = false
		show_error("Can't move in air!")
		return

	await wait_for_player()

	player.is_jumping = false


func perform_jump_left():

	player.is_jumping = true

	var success = player.move_up()

	if not success:
		show_error("Jump blocked!")
		return

	await wait_for_player()

	success = player.move_up()

	if success:
		await wait_for_player()

	success = player.move_left()

	if not success:
		player.is_jumping = false
		show_error("Can't move in air!")
		return

	await wait_for_player()

	player.is_jumping = false


# ==================================================
# UI
# ==================================================

func update_queue_display(current_index = -1):

	queue_display.text = ""

	for i in range(command_queue.size()):

		var command = command_queue[i]

		var text = str(command)

		if i == current_index:
			queue_display.text += "[color=yellow]▶ " + text + "[/color]\n"
		else:
			queue_display.text += text + "\n"


func show_error(message):

	error_label.text = message

	await get_tree().create_timer(2.0).timeout

	error_label.text = ""


# ==================================================
# GOAL
# ==================================================

func _on_goal_body_entered(body):

	if body.name == "Player":

		if coins_collected >= 1:
			print("LEVEL COMPLETE!")
		else:
			show_error("Collect the coin first!")


# ==================================================
# COIN
# ==================================================

func _on_coin_body_entered(body):

	if body.name == "Player":

		coins_collected += 1

		print("Coin diambil!")

		$Coin.queue_free()


# ==================================================
# RESTART
# ==================================================

func _on_restart_button_pressed():

	restart_level()


func restart_level():

	player.reset_player()

	player.is_dead = false

	command_queue.clear()

	update_queue_display()

	error_label.text = ""


# ==================================================
# SPIKE
# ==================================================

func _on_spike_body_entered(body):

	if body.name == "Player":

		player.die()

		show_error("You died!")

		await get_tree().create_timer(1.0).timeout

		restart_level()
