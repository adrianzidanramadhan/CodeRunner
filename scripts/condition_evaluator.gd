extends RefCounted
class_name ConditionEvaluator

static func evaluate(condition, player):

	match condition:
		"wall_right()":
			return player.wall_on_right()

		"spike_ahead()":
			return player.spike_ahead()

	return false
