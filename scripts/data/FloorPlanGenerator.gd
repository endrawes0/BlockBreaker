extends RefCounted
class_name FloorPlanGenerator

const RESERVED_TYPES: Array[String] = ["boss", "victory", "start"]

func generate(config: FloorPlanGeneratorConfig) -> Dictionary:
	if config == null:
		return {}
	var rng := RandomNumberGenerator.new()
	var seed_value: int = config.seed
	if seed_value == 0:
		seed_value = int(Time.get_unix_time_from_system())
	rng.seed = seed_value

	var plan := {
		"start_room_id": "start",
		"rooms": [],
		"seed": seed_value
	}

	var floors: int = _resolve_floor_count(config)
	var rooms: Array[Dictionary] = []
	var room_index: Dictionary = {}

	var start_room: Dictionary = {"id": "start", "type": "combat", "next": []}
	rooms.append(start_room)
	room_index["start"] = 0
	var prev_ids: Array[String] = ["start"]

	for floor in range(floors):
		var act_settings := _act_settings_for_floor(config, floor)
		var weights := _sanitize_weights(Dictionary(act_settings.get("room_weights", config.room_weights)))
		var min_choices: int = max(1, int(act_settings.get("min_choices", config.min_choices)))
		var max_choices: int = max(min_choices, int(act_settings.get("max_choices", config.max_choices)))
		var choice_count: int = rng.randi_range(min_choices, max_choices)

		var floor_ids: Array[String] = []
		for index in range(choice_count):
			var room_type := _pick_weighted(weights, rng)
			var room_id := "f%d_%d" % [floor + 1, index + 1]
			var room: Dictionary = {"id": room_id, "type": room_type, "next": []}
			room_index[room_id] = rooms.size()
			rooms.append(room)
			floor_ids.append(room_id)
		for prev_id in prev_ids:
			_append_next(rooms, room_index, prev_id, floor_ids)
		prev_ids = floor_ids

	var boss_id := "boss"
	var boss_room: Dictionary = {"id": boss_id, "type": "boss", "next": []}
	room_index[boss_id] = rooms.size()
	rooms.append(boss_room)
	for prev_id in prev_ids:
		_append_next(rooms, room_index, prev_id, [boss_id])

	plan["rooms"] = rooms
	return plan

func _resolve_floor_count(config: FloorPlanGeneratorConfig) -> int:
	if config.acts.is_empty():
		return max(1, config.floors)
	var total: int = 0
	for act in config.acts:
		total += max(0, int(act.get("floors", 0)))
	return max(1, total if total > 0 else config.floors)

func _act_settings_for_floor(config: FloorPlanGeneratorConfig, floor_index: int) -> Dictionary:
	if config.acts.is_empty():
		return {}
	var cursor: int = 0
	for act in config.acts:
		var act_floors: int = max(0, int(act.get("floors", 0)))
		if act_floors == 0:
			continue
		if floor_index < cursor + act_floors:
			return act
		cursor += act_floors
	return {}

func _sanitize_weights(weights: Dictionary) -> Dictionary:
	var sanitized: Dictionary = {}
	for key in weights.keys():
		var room_type := String(key).strip_edges().to_lower()
		if room_type == "" or RESERVED_TYPES.has(room_type):
			continue
		var weight: int = int(weights[key])
		if weight > 0:
			sanitized[room_type] = weight
	if sanitized.is_empty():
		sanitized["combat"] = 1
	return sanitized

func _pick_weighted(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var keys: Array = weights.keys()
	keys.sort()
	var total: int = 0
	for key in keys:
		total += int(weights[key])
	if total <= 0:
		return "combat"
	var roll: int = rng.randi_range(1, total)
	var cumulative: int = 0
	for key in keys:
		cumulative += int(weights[key])
		if roll <= cumulative:
			return String(key)
	return "combat"

func _append_next(rooms: Array[Dictionary], room_index: Dictionary, room_id: String, next_ids: Array[String]) -> void:
	if not room_index.has(room_id):
		return
	var index: int = int(room_index[room_id])
	var entry: Dictionary = rooms[index]
	var next_list: Array = entry.get("next", [])
	for next_id in next_ids:
		if not next_list.has(next_id):
			next_list.append(next_id)
	entry["next"] = next_list
	rooms[index] = entry
