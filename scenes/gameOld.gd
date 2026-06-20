#game.gd
extends Node2D

@onready var code_input = $UI/BottomLeftLayout/CodeInput
@onready var player = $Player
@onready var ui = $UI

@export var level_number = LevelManager.current_level

var command_queue = []
var variables = {}
var functions = {}
var coins_collected = 0
var execution_limit = 1000
var execution_count = 0
var current_line = -1
var is_paused = false
var step_count = 0
var has_error = false
var step_mode = false
var waiting_for_step = false
var runtime_stopped = false
var level_finished = false

var coin_completed = false
var portal_completed = false

var tutorial_data = {
	1: [
		{
			"text": "Halo! Aku Knight.\n",
			"mood": "idle"
		},
		{
			"text": "Aku akan mengajarkan command dasar.\n",
			"mood": "idle"
		},
		{
			"text": "Coba ketik: [color=yellow]move_right(3)[/color]\n",
			"mood": "idle"
		}
	],
	2: [
		{
			"text": "Sekarang kita belajar loop.",
			"mood": "idle"
		},
		{
			"text": "Gunakan [color=blue]repeat()[/color] agar kode lebih singkat.",
			"mood": "idle"
		}
	]
}

func _ready():
	
	AudioManager.fade_to_bgm("gameplay")
	
	print(
		"Progress saved: current=",
		LevelManager.current_level,
		", unlocked=",
		LevelManager.unlocked_level
	)

	ui.run_pressed.connect(_on_ui_run_pressed)

	ui.restart_pressed.connect(
		_on_ui_restart_pressed
	)
	
	ui.update_objectives(
		false,
		false
	)
	
	if tutorial_data.has(level_number):
		ui.start_tutorial(
			tutorial_data[level_number]
		)

func _on_ui_run_pressed():

	_on_run_button_pressed()

func _on_ui_restart_pressed():

	restart_level()

func should_stop():
	
	return runtime_stopped \
		or has_error \
		or player.is_dead \
		or level_finished

	#return (
		#runtime_stopped
		#or player.is_dead
		#or level_finished
	#)


# ==================================================
# RUN
# ==================================================

func _on_run_button_pressed():

	runtime_stopped = false
	has_error = false

	step_mode = false
	waiting_for_step = false
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

			var func_text = line.replace("func", "")
			func_text = func_text.replace(":", "")
			func_text = func_text.strip_edges()

			var start = func_text.find("(")
			var end = func_text.find(")")

			var func_name = func_text.substr(0, start).strip_edges()

			var params_text = func_text.substr(
				start + 1,
				end - start - 1
			)

			var params = []

			if params_text.strip_edges() != "":

				var split_params = params_text.split(",")

				for item in split_params:
					params.append(item.strip_edges())
				
				for param_index in range(params.size()):
					params[param_index] = params[param_index].strip_edges()

			var func_indent = get_indent(lines[i])

			var result = parse_block(
				lines,
				i + 1,
				func_indent
			)

			functions[func_name] = {
				"params": params,
				"commands": result["commands"]
			}

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

			var amount_text = line.substr(
				start + 1,
				end - start - 1
			).strip_edges()

			if amount_text == "":

				ui.show_error(
					"Repeat missing amount at line %d"
					% [i + 1]
				)
				AudioManager.play_error()

				runtime_stopped = true
				return

			var repeat_indent = get_indent(lines[i])

			var result = parse_block(
				lines,
				i + 1,
				repeat_indent
			)

			command_queue.append({
				"type": "repeat",
				"amount": amount_text,
				"commands": result["commands"],
				"line": i
			})

			i = result["next_index"] - 1

		# ==========================================
		# WHILE
		# ==========================================
		elif line.begins_with("while"):

			var condition_text = line.replace("while", "")
			condition_text = condition_text.replace(":", "")
			condition_text = condition_text.strip_edges()

			# VALIDASI CONDITION
			if condition_text == "":

				ui.show_error(
					"While missing condition at line %d"
					% [i + 1]
				)
				AudioManager.play_error()

				runtime_stopped = true
				return

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

			i = result["next_index"] - 1


		# ==========================================
		# NORMAL COMMAND
		# ==========================================
		else:

			parse_single_command(line, i)

		i += 1


# ==================================================
# PARSE SINGLE COMMAND
# ==================================================

func parse_single_command(line, line_number = -1):

	var command_data = parse_command_data(line)

	if command_data != null:

		command_data["line"] = line_number

		command_queue.append(command_data)

	else:

		ui.show_error(
			"Unknown command at line %d: %s"
			% [line_number + 1, line]
		)
		AudioManager.play_error()

		runtime_stopped = true


func validate_amount(amount):

	if amount < 1:
		ui.show_error("Amount must be > 0")
		AudioManager.play_error()
		return 1

	if amount > 20:
		ui.show_error("Amount too large!")
		AudioManager.play_error()
		return 20

	return amount


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
			"amount": validate_amount(get_amount(line))
		}

	# ==========================================
	# MOVE LEFT
	# ==========================================
	elif line.begins_with("move_left"):

		return {
			"type": "move",
			"direction": "left",
			"amount": validate_amount(get_amount(line))
		}

	# ==========================================
	# JUMP RIGHT
	# ==========================================
	elif line.begins_with("jump_right"):

		return {
			"type": "jump_right"
		}

	# ==========================================
	# JUMP LEFT
	# ==========================================
	elif line.begins_with("jump_left"):

		return {
			"type": "jump_left"
		}

	# ==========================================
	# JUMP
	# ==========================================
	elif line == "jump()" or line == "jump":

		return {
			"type": "jump"
		}

	# ==========================================
	# FUNCTION CALL
	# ==========================================
	elif "(" in line and line.ends_with(")"):

		var start = line.find("(")
		var end = line.find(")")

		var func_name = line.substr(0, start).strip_edges()

		if functions.has(func_name):

			var args_text = line.substr(
				start + 1,
				end - start - 1
			)

			var args = []

			if args_text.strip_edges() != "":

				var split_args = args_text.split(",")

				for item in split_args:

					args.append(
						evaluate_expression(
							item.strip_edges()
						)
					)

			return {
				"type": "function_call",
				"name": func_name,
				"args": args
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

	if !number_text.is_valid_int():

		ui.show_error(
			"Invalid number: " + number_text
		)
		AudioManager.play_error()

		runtime_stopped = true

		return 1

	return int(number_text)


# ==================================================
# GET INDENT
# ==================================================

func get_indent(line):

	var count = 0

	for letter in line:

		if letter == " ":
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
	# BOOLEAN LITERAL
	# ======================================
	if condition_text == "true":
		return true

	if condition_text == "false":
		return false

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

	# VARIABLE BOOLEAN
	if variables.has(condition_text):

		return bool(variables[condition_text])

	return false


# ==================================================
# GET VALUE
# ==================================================

func get_value(text):

	text = text.strip_edges()

	# boolean
	if text == "true":
		return true

	if text == "false":
		return false

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
	
	if condition == "":

		ui.show_error(
			"If missing condition at line %d"
			% [start_index + 1]
		)
		AudioManager.play_error()

		runtime_stopped = true

		return {
			"command": {},
			"next_index": start_index + 1
		}

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

			"line": start_index,

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
				"commands": result["commands"],
				"line": i
			})

			i = result["next_index"] - 1

		# ======================================
		# REPEAT
		# ======================================
		elif line.begins_with("repeat"):

			var start = line.find("(")
			var end = line.find(")")

			var amount_text = line.substr(
				start + 1,
				end - start - 1
			).strip_edges()

			var result = parse_block(
				lines,
				i + 1,
				indent
			)

			commands.append({
				"type": "repeat",
				"amount": amount_text,
				"commands": result["commands"],
				"line": i
			})

			i = result["next_index"] - 1

		# ======================================
		# IF
		# ======================================
		elif line.begins_with("if"):

			var result = parse_if_statement(lines, i)

			result["command"]["line"] = i

			commands.append(result["command"])

			i = result["next_index"] - 1

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

		if level_finished:
			return

		if should_stop():
			return

		if has_error:
			return

		ui.update_queue_display(
			command_queue,
			i
		)

		var command = command_queue[i]

		current_line = command.get("line", -1)

		ui.highlight_line(current_line)

		await execute_command(command)

	ui.update_queue_display(command_queue)
	
	player.stop_action()


# ==================================================
# EXECUTE SINGLE COMMAND
# ==================================================

func execute_command(command):

	if level_finished:
		return

	if should_stop():
		return

	execution_count += 1

	if execution_count > execution_limit:

		ui.show_error(
			"Infinite loop detected!",
			command.get("line", -1)
		)
		AudioManager.play_error()
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
					success = await player.move_right()

				elif direction == "left":
					success = await player.move_left()

				if not success:
					runtime_stopped = true
					ui.show_error(
						"Movement blocked!",
						command.get("line", -1)
					)
					AudioManager.play_error()
					return
				
				if should_stop():
					return

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

				await execute_command_list(true_commands)

			# ======================================
			# FALSE
			# ======================================
			else:

				var false_commands = command["false_commands"]

				await execute_command_list(false_commands)
			
		# ======================================
		# FUNCTION CALL
		# ======================================
		"function_call":

			var func_name = command["name"]

			if functions.has(func_name):

				var func_data = functions[func_name]

				var params = func_data["params"]
				var commands = func_data["commands"]

				var args = command.get("args", [])

				# save old variables
				var old_variables = variables.duplicate()

				# assign params
				for p in range(params.size()):

					if p < args.size():

						variables[params[p]] = args[p]

				# execute
				for cmd in commands:

					await execute_command(cmd)

				# restore variables
				variables = old_variables
		
		
		# ======================================
		# WHILE
		# ======================================
		"while":

			var condition = command["condition"]
			var loop_commands = command["commands"]

			var safety = 0
			var max_loop = 100

			while true:

				if should_stop():
					break

				if !evaluate_condition(condition):
					break

				safety += 1

				if safety > max_loop:
					ui.show_error("Infinite loop detected!")
					AudioManager.play_error()
					return

				await execute_command_list(loop_commands)

				await get_tree().process_frame


		# ======================================
		# REPEAT
		# ======================================
		"repeat":

			var amount_text = str(command["amount"])

			var repeat_amount = evaluate_expression(amount_text)

			var repeat_commands = command["commands"]

			for r in range(repeat_amount):

				if should_stop():
					return

				await execute_command_list(repeat_commands)

	# ==========================================
	# APPLY GRAVITY
	# ==========================================
	while player.should_fall() and !player.is_airborne():
		await player.move_down()


func execute_command_list(commands):

	for cmd in commands:

		if level_finished:
			return

		if should_stop():
			return

		await execute_command(cmd)


# ==================================================
# WAIT PLAYER
# ==================================================

#func wait_for_player():
#
	#while is_instance_valid(player) and player.is_moving:
#
		#if !is_inside_tree():
			#return
#
		#await get_tree().process_frame


# ==================================================
# JUMP FUNCTIONS
# ==================================================

func perform_jump():
	var success = await player.jump_up()

	if !success:
		ui.show_error("Jump failed!")
		AudioManager.play_error()


func perform_jump_right():

	var success = await player.jump_right()

	if !success:

		ui.show_error(
			"Jump failed!"
		)
		AudioManager.play_error()


func perform_jump_left():

	var success = await player.jump_left()

	if !success:

		ui.show_error(
			"Jump failed!"
		)
		AudioManager.play_error()


# ==================================================
# UI
# ==================================================

#func update_queue_display(current_index = -1):
#
	#queue_display.text = ""
#
	#for i in range(command_queue.size()):
#
		#var command = command_queue[i]
#
		#var text = str(command)
#
		#if i == current_index:
			#queue_display.text += "[color=yellow]▶ " + text + "[/color]\n"
		#else:
			#queue_display.text += text + "\n"


#func show_error(message, line = -1):
#
	#has_error = true
#
	#if line >= 0:
#
		#error_label.text = "Line " + str(line + 1) + ": " + message
#
	#else:
#
		#error_label.text = message
#
	#print(error_label.text)


# ==================================================
# GOAL
# ==================================================

func _on_goal_body_entered(body):

	if body.name != "Player":
		return

	if coins_collected < 1:
		ui.show_error("Collect the coin first!")
		AudioManager.play_error()
		return

	#AudioManager.stop_bgm()
	AudioManager.play_sfx("portal")
	level_finished = true

	LevelManager.unlock_level(
		level_number + 1
	)

	portal_completed = true

	ui.update_objectives(
		coin_completed,
		portal_completed
	)

	call_deferred("_show_finish_popup")

func _show_finish_popup():
	ui.show_level_complete(level_number)

# ==================================================
# COIN
# ==================================================

func _on_coin_body_entered(body):

	if body.name != "Player":
		return

	AudioManager.play_sfx("coin")
	coins_collected += 1
	
	coin_completed = true
	
	ui.update_objectives(
		coin_completed,
		portal_completed
	)

	$Coin.queue_free()


# ==================================================
# RESTART
# ==================================================

func _on_restart_button_pressed():

	restart_level()


func restart_level():

	runtime_stopped = false
	has_error = false
	level_finished = false

	player.reset_player()
	player.is_dead = false
	
	command_queue.clear()
	
	coin_completed = false
	portal_completed = false

	ui.update_objectives(
		false,
		false
	)

	ui.update_queue_display(command_queue)
	ui.clear_error()


# ==================================================
# SPIKE
# ==================================================

func _on_spike_body_entered(body):

	if body.name != "Player":
		return

	if body.is_airborne():
		return

	runtime_stopped = true

	await player.die()

	ui.show_error("You died!")
	AudioManager.play_error()

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


#func highlight_current_line():
#
	#if current_line >= 0:
#
		#code_input.set_caret_line(current_line)
#
		#code_input.center_viewport_to_caret()
