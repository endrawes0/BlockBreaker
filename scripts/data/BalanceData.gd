extends Resource
class_name BalanceData

@export var card_data: Dictionary = {}
@export var card_pool: Array[String] = []
@export var starting_deck: Array[String] = []

@export var ball_mod_data: Dictionary = {}
@export var ball_mod_order: Array[String] = []
@export var ball_mod_colors: Dictionary = {}

@export var shop_card_price: int = 40
@export var shop_remove_price: int = 30
@export var shop_upgrade_price: int = 60
@export var shop_upgrade_hand_bonus: int = 1
@export var shop_vitality_price: int = 60
@export var shop_vitality_max_hp_bonus: int = 10
@export var shop_vitality_heal: int = 10
@export var shop_reroll_base_price: int = 20
@export var shop_reroll_multiplier: float = 1.8
@export var reward_card_count: int = 3
@export var shop_energy_price: int = 70
@export var shop_energy_bonus: int = 1
@export var shop_paddle_width_price: int = 60
@export var shop_paddle_width_bonus: float = 10.0
@export var shop_paddle_speed_price: int = 60
@export var shop_paddle_speed_bonus_percent: float = 10.0
@export var shop_reserve_ball_price: int = 80
@export var shop_reserve_ball_bonus: int = 1
@export var shop_threat_reduction_price: int = 70
@export var shop_threat_reduction_amount: int = 4
@export var shop_energy_refund_price: int = 90
@export var shop_energy_refund_amount: int = 1
@export var shop_discount_price: int = 50
@export var shop_discount_percent: float = 20.0
@export var shop_entry_card_price: int = 70
@export var shop_entry_card_count: int = 1
