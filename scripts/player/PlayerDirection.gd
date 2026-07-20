extends RefCounted
class_name PlayerDirection

enum Direction {
	LEFT,
	RIGHT
}

static func sign(direction:int) -> int:

	if direction == Direction.LEFT:
		return -1

	return 1


static func is_left(direction:int):
	return direction == Direction.LEFT


static func is_right(direction:int):
	return direction == Direction.RIGHT
