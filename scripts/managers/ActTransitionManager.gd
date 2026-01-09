extends Node
class_name ActTransitionManager

enum Step { NONE, BUFF, TREASURE, REST, SHOP }

const DEFAULT_FADE_SECONDS: float = 4.0
const DEFAULT_PAUSE_SECONDS: float = 4.0
const DEFAULT_BUFF_CHOICES: int = 3

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _pending: bool = false
var _step: int = Step.NONE
var _prev_plan: Dictionary = {}
var _next_plan: Dictionary = {}
var _map_label_override_act_index: int = -1

var _get_config: Callable = Callable()
var _apply_buff: Callable = Callable()
var _apply_rest_rewards: Callable = Callable()
var _update_labels: Callable = Callable()
var _hide_all_panels: Callable = Callable()
var _show_treasure_panel: Callable = Callable()
var _show_single_panel: Callable = Callable()
var _show_map_preview_from_plan: Callable = Callable()
var _fade_overlay_to: Callable = Callable()
var _enter_shop_step: Callable = Callable()
var _exit_sequence: Callable = Callable()

var _treasure_panel: Control = null
var _treasure_label: Label = null
var _treasure_rewards_container: Node = null
var _treasure_continue_button: Button = null

func setup(
		rng: RandomNumberGenerator,
		ui: Dictionary,
		hooks: Dictionary
	) -> void:
	_rng = rng if rng != null else RandomNumberGenerator.new()
	_treasure_panel = ui.get("treasure_panel") as Control
	_treasure_label = ui.get("treasure_label") as Label
	_treasure_rewards_container = ui.get("treasure_rewards") as Node
	_treasure_continue_button = ui.get("treasure_continue_button") as Button

	_get_config = hooks.get("get_config", Callable())
	_apply_buff = hooks.get("apply_buff", Callable())
	_apply_rest_rewards = hooks.get("apply_rest_rewards", Callable())
	_update_labels = hooks.get("update_labels", Callable())
	_hide_all_panels = hooks.get("hide_all_panels", Callable())
	_show_treasure_panel = hooks.get("show_treasure_panel", Callable())
	_show_single_panel = hooks.get("show_single_panel", Callable())
	_show_map_preview_from_plan = hooks.get("show_map_preview_from_plan", Callable())
	_fade_overlay_to = hooks.get("fade_overlay_to", Callable())
	_enter_shop_step = hooks.get("enter_shop_step", Callable())
	_exit_sequence = hooks.get("exit_sequence", Callable())

func queue_sequence(prev_plan: Dictionary, next_plan: Dictionary) -> void:
	_prev_plan = prev_plan.duplicate(true) if prev_plan != null else {}
	_next_plan = next_plan.duplicate(true) if next_plan != null else {}
	_pending = true

func has_pending() -> bool:
	return _pending

func maybe_start_sequence() -> bool:
	if not _pending:
		return false
	_pending = false
	_step = Step.BUFF
	_show_buff_choice()
	return true

func current_step() -> int:
	return _step

func map_label_override_act_index() -> int:
	return _map_label_override_act_index

func handle_treasure_continue() -> bool:
	if _step != Step.TREASURE:
		return false
	_step = Step.REST
	call_deferred("_run_rest_transition")
	return true

func handle_shop_continue() -> bool:
	if _step != Step.SHOP:
		return false
	_step = Step.NONE
	_map_label_override_act_index = -1
	if _exit_sequence.is_valid():
		_exit_sequence.call()
	return true

func _clear_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()

func _get_cfg_value(cfg: Dictionary, key: String, fallback):
	return cfg.get(key, fallback) if cfg != null else fallback

func _buff_candidates() -> Array[Dictionary]:
	var cfg: Dictionary = _get_config.call() if _get_config.is_valid() else {}
	var options: Array[Dictionary] = []

	var shop_upgrade_hand_bonus: int = int(_get_cfg_value(cfg, "shop_upgrade_hand_bonus", 0))
	var shop_max_hand_size: int = int(_get_cfg_value(cfg, "shop_max_hand_size", 0))
	var starting_hand_size: int = int(_get_cfg_value(cfg, "starting_hand_size", 0))
	options.append({
		"id": "upgrade_hand",
		"text": "Upgrade starting hand (+%d)" % shop_upgrade_hand_bonus,
		"enabled": shop_upgrade_hand_bonus > 0 and (shop_max_hand_size <= 0 or starting_hand_size < shop_max_hand_size)
	})

	var shop_vitality_max_hp_bonus: int = int(_get_cfg_value(cfg, "shop_vitality_max_hp_bonus", 0))
	var shop_vitality_heal: int = int(_get_cfg_value(cfg, "shop_vitality_heal", 0))
	options.append({
		"id": "vitality",
		"text": "Vitality (+%d max HP, heal %d)" % [shop_vitality_max_hp_bonus, shop_vitality_heal],
		"enabled": shop_vitality_max_hp_bonus > 0 or shop_vitality_heal > 0
	})

	var shop_energy_bonus: int = int(_get_cfg_value(cfg, "shop_energy_bonus", 0))
	var max_energy_bonus: int = int(_get_cfg_value(cfg, "max_energy_bonus", 0))
	options.append({
		"id": "surge",
		"text": "Surge (+%d max energy)" % shop_energy_bonus,
		"enabled": shop_energy_bonus > 0 and max_energy_bonus < 2
	})

	var shop_paddle_width_bonus: float = float(_get_cfg_value(cfg, "shop_paddle_width_bonus", 0.0))
	options.append({
		"id": "paddle_width",
		"text": "Wider Paddle (+%d width)" % int(round(shop_paddle_width_bonus)),
		"enabled": shop_paddle_width_bonus > 0.0
	})

	var shop_paddle_speed_bonus_percent: float = float(_get_cfg_value(cfg, "shop_paddle_speed_bonus_percent", 0.0))
	options.append({
		"id": "paddle_speed",
		"text": "Paddle Speed (+%d%%)" % int(round(shop_paddle_speed_bonus_percent)),
		"enabled": shop_paddle_speed_bonus_percent > 0.0
	})

	var shop_reserve_ball_bonus: int = int(_get_cfg_value(cfg, "shop_reserve_ball_bonus", 0))
	var volley_ball_bonus_base: int = int(_get_cfg_value(cfg, "volley_ball_bonus_base", 0))
	options.append({
		"id": "reserve_ball",
		"text": "Reserve Ball (+%d per volley)" % shop_reserve_ball_bonus,
		"enabled": shop_reserve_ball_bonus > 0 and volley_ball_bonus_base < 1
	})

	var shop_discount_percent: float = float(_get_cfg_value(cfg, "shop_discount_percent", 0.0))
	options.append({
		"id": "shop_discount",
		"text": "Shop Discount (-%d%% prices)" % int(round(shop_discount_percent)),
		"enabled": shop_discount_percent > 0.0
	})

	var shop_entry_card_count: int = int(_get_cfg_value(cfg, "shop_entry_card_count", 0))
	options.append({
		"id": "shop_scribe",
		"text": "Shop Scribe (+%d card on entry)" % shop_entry_card_count,
		"enabled": shop_entry_card_count > 0
	})

	return options

func _roll_buffs(count: int) -> Array[Dictionary]:
	var candidates := _buff_candidates()
	var enabled: Array[Dictionary] = []
	for option in candidates:
		if bool(option.get("enabled", true)):
			enabled.append(option)
	var picked: Array[Dictionary] = []
	if enabled.is_empty():
		return picked
	var target: int = min(count, enabled.size())
	while picked.size() < target:
		var idx: int = _rng.randi_range(0, enabled.size() - 1)
		picked.append(enabled.pop_at(idx))
	return picked

func _show_buff_choice() -> void:
	if _hide_all_panels.is_valid():
		_hide_all_panels.call()
	if _show_single_panel.is_valid() and _treasure_panel != null:
		_show_single_panel.call(_treasure_panel)
	if _treasure_label != null:
		_treasure_label.text = "Act Rewards: Buff"
	if _treasure_continue_button != null:
		_treasure_continue_button.visible = false
	_clear_children(_treasure_rewards_container)

	var buffs := _roll_buffs(DEFAULT_BUFF_CHOICES)
	if buffs.is_empty():
		_step = Step.TREASURE
		_show_treasure_step()
		return
	for buff in buffs:
		var buff_id: String = String(buff.get("id", ""))
		var text: String = String(buff.get("text", buff_id))
		var button := Button.new()
		button.text = text
		button.pressed.connect(func() -> void:
			if _apply_buff.is_valid():
				_apply_buff.call(buff_id)
			if _update_labels.is_valid():
				_update_labels.call()
			_step = Step.TREASURE
			_show_treasure_step()
		)
		App.apply_neutral_button_style(button)
		App.bind_button_feedback(button)
		if _treasure_rewards_container != null:
			_treasure_rewards_container.add_child(button)

func _show_treasure_step() -> void:
	if _hide_all_panels.is_valid():
		_hide_all_panels.call()
	if _show_treasure_panel.is_valid():
		_show_treasure_panel.call(true)
	if _treasure_label != null:
		_treasure_label.text = "Act Rewards: Treasure"
	if _treasure_continue_button != null:
		_treasure_continue_button.text = "Continue"
		_treasure_continue_button.visible = true

func _run_rest_transition() -> void:
	var fade_seconds: float = DEFAULT_FADE_SECONDS
	var pause_seconds: float = DEFAULT_PAUSE_SECONDS
	var cfg: Dictionary = _get_config.call() if _get_config.is_valid() else {}
	if cfg.has("rest_fade_seconds"):
		fade_seconds = float(cfg.get("rest_fade_seconds"))
	if cfg.has("rest_pause_seconds"):
		pause_seconds = float(cfg.get("rest_pause_seconds"))

	if not _prev_plan.is_empty() and _show_map_preview_from_plan.is_valid():
		_map_label_override_act_index = int(_prev_plan.get("active_act_index", -1))
		_show_map_preview_from_plan.call(_prev_plan)
	else:
		_map_label_override_act_index = -1
		if _hide_all_panels.is_valid():
			_hide_all_panels.call()

	if _fade_overlay_to.is_valid():
		await _fade_overlay_to.call(1.0, fade_seconds)

	if _apply_rest_rewards.is_valid():
		_apply_rest_rewards.call()
	if _update_labels.is_valid():
		_update_labels.call()

	await get_tree().create_timer(pause_seconds).timeout

	if not _next_plan.is_empty() and _show_map_preview_from_plan.is_valid():
		_map_label_override_act_index = int(_next_plan.get("active_act_index", -1))
		_show_map_preview_from_plan.call(_next_plan)
	else:
		_map_label_override_act_index = -1

	if _fade_overlay_to.is_valid():
		await _fade_overlay_to.call(0.0, fade_seconds)

	_step = Step.SHOP
	if _enter_shop_step.is_valid():
		_enter_shop_step.call()
