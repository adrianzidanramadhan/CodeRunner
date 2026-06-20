extends RefCounted
class_name CommandParser

var last_error = ""


func reset():
	last_error = ""


func parse(code: String):

	reset()

	var lines = code.split("\n")
	var result = parse_block(lines, 0, -1)

	if last_error != "":
		return null

	return result["commands"]


func set_error(message):
	last_error = message


# ==================================================
# PARSE SINGLE COMMAND
# ==================================================

func parse_single_command(line, line_number = -1):

	var command_data = parse_command_data(line)

	if command_data != null:
		command_data["line"] = line_number
		return command_data

	set_error("Unknown command at line %d: %s" % [line_number + 1, line])
	return null


func validate_amount(amount):

	if amount == null:
		return null

	if amount < 1:
		set_error("Amount must be > 0")
		return null

	if amount > 20:
		set_error("Amount too large")
		return null

	return amount


# ==================================================
# COMMAND DATA
# ==================================================

func parse_command_data(line):

	# ==========================================
	# MOVE RIGHT
	# ==========================================
	if line.begins_with("move_right"):

		var amount = validate_amount(
			get_amount(line)
		)

		if amount == null:
			return null

		return {
			"type": "move",
			"direction": "right",
			"amount": amount
		}

	# ==========================================
	# MOVE LEFT
	# ==========================================
	elif line.begins_with("move_left"):

		var amount = validate_amount(
			get_amount(line)
		)

		if amount == null:
			return null

		return {
			"type": "move",
			"direction": "left",
			"amount": amount
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

	return null


# ==================================================
# GET AMOUNT
# ==================================================

func get_amount(line):

	var start = line.find("(")
	var end = line.find(")")

	if start == -1 or end == -1:
		return 1

	var text = line.substr(start + 1, end - start - 1).strip_edges()

	if text == "":
		return 1

	if !text.is_valid_int():
		set_error("Invalid number: " + text)
		return null

	return int(text)


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
# PARSE IF
# ==================================================

func parse_if_statement(lines, start_index):

	var line = lines[start_index].strip_edges()

	var current_indent = get_indent(lines[start_index])

	# ======================================
	# CONDITION
	# ======================================
	var condition = extract_condition(line, "if")
	
	if condition == "":

		set_error(
			"If missing condition at line %d"
			% [start_index + 1]
		)

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

			var fake_lines = lines.duplicate()
			fake_lines[i] = elif_line
			var elif_result = parse_if_statement(fake_lines, i)

			if elif_result["command"].is_empty():
				return {
					"command": {},
					"next_index": lines.size()
				}

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


func extract_condition(line:String, keyword:String):
	var result = line.replace(keyword, "")
	result = result.replace(":", "")
	return result.strip_edges()


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

			var condition_text = extract_condition(line, "while")

			var result = parse_block(
				lines,
				i + 1,
				indent
			)

			if condition_text == "":
				set_error("While missing condition")
				return {
					"commands": [],
					"next_index": lines.size()
				}

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

			var amount = validate_amount(get_amount(line))

			if amount == null:
				return {
					"commands": [],
					"next_index": lines.size()
				}

			var result = parse_block(
				lines,
				i + 1,
				indent
			)

			commands.append({
				"type": "repeat",
				"amount": amount,
				"commands": result["commands"],
				"line": i
			})

			i = result["next_index"] - 1

		# ======================================
		# IF
		# ======================================
		elif line.begins_with("if"):

			var result = parse_if_statement(lines, i)

			if result["command"].is_empty():
				return {
					"commands": [],
					"next_index": lines.size()
				}

			commands.append(result["command"])

			i = result["next_index"] - 1

		# ======================================
		# NORMAL COMMAND
		# ======================================
		else:

			var command_data = parse_single_command(line, i)

			if command_data != null:
				commands.append(command_data)

		i += 1

	return {
		"commands": commands,
		"next_index": i
	}
