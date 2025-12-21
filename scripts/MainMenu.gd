extends Control

@onready var start_button: Button = $Center/VBox/StartButton
@onready var help_button: Button = $Center/VBox/HelpButton
@onready var test_button: Button = $Center/VBox/TestButton
@onready var quit_button: Button = $Center/VBox/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_start_game)
	help_button.pressed.connect(_open_help)
	test_button.pressed.connect(_open_test_lab)
	quit_button.pressed.connect(_quit_game)

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _open_help() -> void:
	get_tree().change_scene_to_file("res://scenes/Help.tscn")

func _open_test_lab() -> void:
	get_tree().change_scene_to_file("res://scenes/TestLab.tscn")

func _quit_game() -> void:
	get_tree().quit()
