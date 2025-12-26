extends Node
class_name MapManager

@export var floor_plan: FloorPlan

func build_room_choices(floor_index: int, max_combat_floors: int) -> Array[String]:
	if floor_plan != null and floor_plan.rooms.size() > 0:
		return _choices_from_floor_plan(floor_index, max_combat_floors)
	return _fallback_choices(floor_index, max_combat_floors)

func room_label(room_type: String) -> String:
	match room_type:
		"combat":
			return "Combat"
		"elite":
			return "Elite"
		"rest":
			return "Rest"
		"shop":
			return "Shop"
		"boss":
			return "Boss"
		"victory":
			return "Victory"
		_:
			return "???"

func _choices_from_floor_plan(floor_index: int, max_combat_floors: int) -> Array[String]:
	# TODO: Implement room-graph traversal. Use weighted fallback to avoid duplicates for now.
	return _fallback_choices(floor_index, max_combat_floors)

func _fallback_choices(floor_index: int, max_combat_floors: int) -> Array[String]:
	if floor_index >= max_combat_floors:
		return ["boss"]
	var pool: Array[String] = ["combat", "combat", "combat", "rest", "shop", "elite"]
	var first_choice := pool.pick_random()
	var filtered_pool: Array[String] = []
	for entry in pool:
		if entry != first_choice:
			filtered_pool.append(entry)
	var second_choice := first_choice
	if not filtered_pool.is_empty():
		second_choice = filtered_pool.pick_random()
	return [first_choice, second_choice]
