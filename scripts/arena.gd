extends Node2D

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const WAVE_SPAWNS := [Vector2(930, 570), Vector2(1080, 570), Vector2(790, 570)]

@onready var player = $Player
@onready var health_label: Label = $CanvasLayer/HUD/Health
@onready var result_label: Label = $CanvasLayer/HUD/Result

var wave_label: Label
var wave := 1
var enemies_alive := 0
var wave_transition := false

func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.player_died.connect(_on_player_died)
	_on_health_changed(3, 3)
	wave_label = Label.new()
	wave_label.position = Vector2(34, 108)
	wave_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.94))
	wave_label.add_theme_font_size_override("font_size", 18)
	$CanvasLayer/HUD.add_child(wave_label)
	_update_wave_label()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_register_enemy(enemy)

func _register_enemy(enemy: Node) -> void:
	enemies_alive += 1
	enemy.defeated.connect(_on_enemy_defeated)
	_update_wave_label()

func _on_enemy_defeated() -> void:
	enemies_alive = maxi(0, enemies_alive - 1)
	if enemies_alive == 0 and wave < 3 and not wave_transition:
		wave_transition = true
		await get_tree().create_timer(1.15).timeout
		if not is_instance_valid(self) or player.dead:
			return
		wave += 1
		var count := wave
		for index in range(count):
			var enemy = ENEMY_SCENE.instantiate()
			enemy.position = WAVE_SPAWNS[index]
			add_child(enemy)
			_register_enemy(enemy)
		wave_transition = false
	elif enemies_alive == 0 and wave == 3:
		result_label.text = "ASHEN GROUNDS CLEARED\nYou survived all three waves"

func _update_wave_label() -> void:
	if is_instance_valid(wave_label):
		wave_label.text = "WAVE  %d / 3     FOES  %d" % [wave, enemies_alive]

func _on_health_changed(current_health: int, max_health: int) -> void:
	var hearts := ""
	for index in range(max_health):
		hearts += "♥ " if index < current_health else "♡ "
	health_label.text = "VITALITY  " + hearts.strip_edges()

func _on_player_died() -> void:
	result_label.text = "FALLEN IN THE ASHEN GROUNDS\nPress R to rise again"
