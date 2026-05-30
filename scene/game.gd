extends Node2D

@onready var code_input = $UI/CodeInput
@onready var player = $Player

@onready var queue_display = $UI/QueueDisplay
@onready var error_label = $UI/ErrorLabel

var command_queue = []
var variables = {}
var functions = {}
var coins_collected = 0
var execution_limit = 1000
var execution_count = 0

# ==================================================
# RUN
# ==================================================

func _on_run_button_pressed():

	execution_count = 0

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

		# skip empty
		if line == "":
			i += 1
			continue

		# ==========================================
		# FUNCTION
		# ==========================================
		if line.begins_with("func"):

			var func_name = line.replace("func", "")
			func_name = func_name.replace("():", "")
			func_name = func_name.strip_edges()

			var func_indent = get_indent(lines[i])

			var result = parse_block(
				lines,
				i + 1,
				func_indent
			)

			functions[func_name] = result["commands"]

			i = result["next_index"] - 1

		# ==========================================
		# VARIABLE
		# ==========================================
		elif line.contains("=") and !line.begins_with("if"):

			var parts = line.split("=")

			if parts.size() >= 2:

				var var_name = parts[0].strip_edges()

				var value_text = parts[1].strip_edges()

				variables[var_name] = evaluate_expression(value_text)

				print("Variable saved:", var_name, variables[var_name])

		# ==========================================
		# REPEAT
		# ==========================================
		elif line.begins_with("repeat"):

			var start = line.find("(")
			var end = line.find(")")

			var number_text = line.substr(start + 1, end - start - 1)

			var repeat_amount = 0

			if variables.has(number_text):
				repeat_amount = variables[number_text]
			else:
				repeat_amount = int(number_text)

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
		# WHILE
		# ==========================================
		elif line.begins_with("while"):

			var condition_text = line.replace("while", "")
			condition_text = condition_text.replace(":", "")
			condition_text = condition_text.strip_edges()

			var while_indent = get_indent(lines[i])

			var result = parse_block(
				lines,
				i + 1,
				while_indent
			)

			command_queue.append({
				"type": "while",
				"condition": condition_text,
				"commands": result["commands"]
			})

			i = result["next_index"] - 1

		# ==========================================
		# IF
		# ==========================================
		elif line.begins_with("if"):

			var result = parse_if_statement(lines, i)

			command_queue.append(result["command"])

			i = result["next_index"]

		# ==========================================
		# NORMAL COMMAND
		# ==========================================
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

	# ==========================================
	# FUNCTION CALL
	# ==========================================
	elif line.ends_with("()"):

		var func_name = line.replace("()", "").strip_edges()

		if functions.has(func_name):

			return {
				"type": "function_call",
				"name": func_name
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


# ==================================================
# GET INDENT
# ==================================================

func get_indent(line):

	var count = 0

	for char in line:

		if char == " ":
			count += 1
		else:
			break

	return count


# ==================================================
# CONDITION EVALUATOR
# ==================================================

func evaluate_condition(condition_text):

	condition_text = condition_text.strip_edges()

	# ======================================
	# AND
	# ======================================
	if condition_text.contains(" and "):

		var parts = condition_text.split(" and ")

		for part in parts:

			if !evaluate_condition(part.strip_edges()):
				return false

		return true

	# ======================================
	# OR
	# ======================================
	if condition_text.contains(" or "):

		var parts = condition_text.split(" or ")

		for part in parts:

			if evaluate_condition(part.strip_edges()):
				return true

		return false

	# ======================================
	# NOT
	# ======================================
	if condition_text.begins_with("not "):

		var inner = condition_text.substr(4).strip_edges()

		return !evaluate_condition(inner)

	# ======================================
	# ==
	# ======================================
	if condition_text.contains("=="):

		var parts = condition_text.split("==")

		return get_value(parts[0].strip_edges()) == get_value(parts[1].strip_edges())

	# ======================================
	# >
	# ======================================
	if condition_text.contains(">"):

		var parts = condition_text.split(">")

		return get_value(parts[0].strip_edges()) > get_value(parts[1].strip_edges())

	# ======================================
	# <
	# ======================================
	if condition_text.contains("<"):

		var parts = condition_text.split("<")

		return get_value(parts[0].strip_edges()) < get_value(parts[1].strip_edges())

	# ======================================
	# BUILTIN CONDITIONS
	# ======================================
	if condition_text == "wall_right()":

		return player.wall_on_right()

	if condition_text == "spike_ahead()":

		return player.spike_ahead()

	return false


# ==================================================
# GET VALUE
# ==================================================

func get_value(text):

	# variable
	if variables.has(text):
		return variables[text]

	# integer
	return int(text)


# ==================================================
# PARSE IF
# ==================================================

func parse_if_statement(lines, start_index):

	var line = lines[start_index].strip_edges()

	var current_indent = get_indent(lines[start_index])

	# ======================================
	# CONDITION
	# ======================================
	var condition = line.replace("if", "")
	condition = condition.replace(":", "")
	condition = condition.strip_edges()

	# ======================================
	# TRUE BLOCK
	# ======================================
	var true_result = parse_block(
		lines,
		start_index + 1,
		current_indent
	)

	var true_commands = true_result["commands"]

	var i = true_result["next_index"]

	# ======================================
	# FALSE BLOCK
	# ======================================
	var false_commands = []

	# ======================================
	# ELIF
	# ======================================
	if i < lines.size():

		var next_line = lines[i].strip_edges()

		if next_line.begins_with("elif"):

			var elif_line = next_line.replace("elif", "if")

			lines[i] = elif_line

			var elif_result = parse_if_statement(lines, i)

			false_commands.append(elif_result["command"])

			i = elif_result["next_index"]

	# ======================================
	# ELSE
	# ======================================
	if i < lines.size():

		var next_line = lines[i].strip_edges()

		if next_line.begins_with("else"):

			var else_indent = get_indent(lines[i])

			var else_result = parse_block(
				lines,
				i + 1,
				else_indent
			)

			false_commands = else_result["commands"]

			i = else_result["next_index"]

	# ======================================
	# RETURN
	# ======================================
	return {

		"command": {

			"type": "if",

			"condition": condition,

			"true_commands": true_commands,

			"false_commands": false_commands
		},

		"next_index": i
	}


# ==================================================
# PARSE BLOCK
# ==================================================

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
		# WHILE
		# ======================================
		if line.begins_with("while"):

			var condition_text = line.replace("while", "")
			condition_text = condition_text.replace(":", "")
			condition_text = condition_text.strip_edges()

			var result = parse_block(
				lines,
				i + 1,
				indent
			)

			commands.append({
				"type": "while",
				"condition": condition_text,
				"commands": result["commands"]
			})

			i = result["next_index"] - 1

		# ======================================
		# IF
		# ======================================
		elif line.begins_with("if"):

			var result = parse_if_statement(lines, i)

			commands.append(result["command"])

			i = result["next_index"]

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

	execution_count += 1

	if execution_count > execution_limit:

		show_error("Infinite loop detected!")
		return

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

			var condition_result = evaluate_condition(condition)

			# ======================================
			# TRUE
			# ======================================
			if condition_result:

				var true_commands = command["true_commands"]

				for cmd in true_commands:

					await execute_command(cmd)

			# ======================================
			# FALSE
			# ======================================
			else:

				var false_commands = command["false_commands"]

				for cmd in false_commands:

					await execute_command(cmd)
			
		# ======================================
		# FUNCTION CALL
		# ======================================
		"function_call":

			var func_name = command["name"]

			if functions.has(func_name):

				var func_commands = functions[func_name]

				for cmd in func_commands:

					await execute_command(cmd)
					
		# ======================================
		# WHILE
		# ======================================
		"while":

			var condition = command["condition"]
			var loop_commands = command["commands"]

			var safety = 0
			var max_loop = 100

			while evaluate_condition(condition):

				safety += 1

				if safety > max_loop:

					show_error("Infinite loop detected!")
					return

				for cmd in loop_commands:

					await execute_command(cmd)

				# PENTING
				await get_tree().process_frame

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

func evaluate_expression(text):

	text = text.strip_edges()

	# ======================================
	# +
	# ======================================
	if text.contains("+"):

		var parts = text.split("+")

		var left = evaluate_expression(parts[0])

		var right = evaluate_expression(parts[1])

		return left + right

	# ======================================
	# -
	# ======================================
	elif text.contains("-"):

		var parts = text.split("-")

		var left = evaluate_expression(parts[0])

		var right = evaluate_expression(parts[1])

		return left - right

	# ======================================
	# *
	# ======================================
	elif text.contains("*"):

		var parts = text.split("*")

		var left = evaluate_expression(parts[0])

		var right = evaluate_expression(parts[1])

		return left * right

	# ======================================
	# /
	# ======================================
	elif text.contains("/"):

		var parts = text.split("/")

		var left = evaluate_expression(parts[0])

		var right = evaluate_expression(parts[1])

		if right == 0:
			return 0

		return left / right

	# ======================================
	# VALUE
	# ======================================
	return get_value(text)
