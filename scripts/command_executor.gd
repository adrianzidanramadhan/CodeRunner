extends Node
class_name CommandExecutor

var player
var ui
var game

func setup(_player, _ui, _game):
	player = _player
	ui = _ui
	game = _game

func execute_commands(commands):

	for i in range(commands.size()):

		if game.level_finished:
			return false

		var command = commands[i]

		ui.update_queue_display(commands, i)

		var success = await execute_command(command)

		if !success:
			return false
		
		await game.post_command_checks()

	player.stop_action()
	return true

func execute_command(command):

	match command["type"]:

		"move":
			return await execute_move(command)

		"jump":
			return await player.jump_up()

		"jump_right":
			return await player.jump_right()

		"jump_left":
			return await player.jump_left()

		"repeat":
			return await execute_repeat(command)

		"if":
			return await execute_if(command)

		"while":
			return await execute_while(command)

	ui.show_error("Unknown command: " + str(command["type"]))
	return false

func execute_move(command):

	var direction = command["direction"]
	var amount = command["amount"]

	for i in range(amount):

		var success = false

		match direction:
			"right":
				success = await player.move_right()
			"left":
				success = await player.move_left()

		if !success:
			ui.show_error("Movement blocked")
			return false

	return true

func execute_repeat(command):

	var amount = command["amount"]
	var commands = command["commands"]

	for i in range(amount):

		var success = await execute_commands(commands)

		if !success:
			return false

	return true

func execute_if(command):

	var condition = command["condition"]

	var commands = command["true_commands"]

	if !evaluate_condition(condition):
		commands = command["false_commands"]

	if commands.is_empty():
		return true

	return await execute_commands(commands)

func execute_while(command):

	var condition = command["condition"]
	var safety_counter = 0
	const MAX_WHILE_LOOPS = 100

	while evaluate_condition(condition):

		safety_counter += 1

		if safety_counter > MAX_WHILE_LOOPS:
			ui.show_error("Infinite loop detected")
			return false

		var success = await execute_commands(
			command["commands"]
		)

		if !success:
			return false

	return true

func evaluate_condition(condition):
	return ConditionEvaluator.evaluate(condition, player)
