extends Node2D

@onready var player = $Player
@onready var health_label: Label = $CanvasLayer/HUD/Health
@onready var result_label: Label = $CanvasLayer/HUD/Result

func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.player_died.connect(_on_player_died)
	_on_health_changed(3, 3)

func _on_health_changed(current_health: int, max_health: int) -> void:
	var hearts := ""
	for index in range(max_health):
		hearts += "♥ " if index < current_health else "♡ "
	health_label.text = "VITALITY  " + hearts.strip_edges()

func _on_player_died() -> void:
	result_label.text = "FALLEN IN THE ASHEN GROUNDS\nPress R to rise again"
