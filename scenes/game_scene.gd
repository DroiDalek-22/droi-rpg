extends Node2D

signal levelup

@export var end_game_screen_packed: PackedScene
@export var pause_menu_packed: PackedScene   # ← NOUVEAU : glisse ta pause_menu.tscn ici dans l'inspecteur

var total_enemies: int = 0
var killed_enemies: int = 0
var pause_menu: Control = null   # Référence pour pouvoir la cacher facilement

func _ready() -> void:
	# ====================== ENNEMIS ======================
	var enemy_array: Array = get_tree().get_nodes_in_group("enemies")
	total_enemies = enemy_array.size()
	for enemy in enemy_array:
		if enemy.has_signal("died"):
			enemy.died.connect(enemy_died)

	# ====================== JOUEUR ======================
	var player = get_tree().get_first_node_in_group("player")
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if player == null:
		push_error("game_scene.gd : Aucun joueur trouvé dans le groupe 'player'.")
		return

	if player.has_method("calculates_stats"):
		levelup.connect(player.calculates_stats)
	if player.has_signal("game_over"):
		player.game_over.connect(display_end_game_screen)

	add_to_group("game_scene")  # Pour les ennemis qui s'auto-connectent

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # Touche Esc par défaut
		toggle_pause()

func toggle_pause() -> void:
	var is_paused = get_tree().paused
	get_tree().paused = not is_paused
	
	if not is_paused:  # On vient de pauser
		if pause_menu == null and pause_menu_packed:
			pause_menu = pause_menu_packed.instantiate()
			pause_menu.resume_requested.connect(_on_pause_resume)
			pause_menu.main_menu_requested.connect(_on_pause_main_menu)
			pause_menu.quit_requested.connect(_on_pause_quit)
			$UI.add_child(pause_menu)
			pause_menu.show()
	else:  # On reprend
		if pause_menu:
			pause_menu.hide()
			pause_menu.queue_free()
			pause_menu = null

# ====================== CALLBACKS DU MENU PAUSE ======================
func _on_pause_resume() -> void:
	toggle_pause()

func _on_pause_main_menu() -> void:
	get_tree().paused = false
	var scene_handler: Node = get_node_or_null("/root/SceneHandler")
	if scene_handler:
		# On passe false car on vient du pause menu (pas d'état "victoire/défaite")
		# Si l'argument est autre chose (String, etc.), tu pourras l'ajuster facilement
		scene_handler.load_main_menu(false)
	else:
		push_error("SceneHandler introuvable")

func _on_pause_quit() -> void:
	get_tree().quit()

# ====================== FONCTIONS EXISTANTES (inchangées) ======================
func enemy_died(exp_reward: int) -> void:
	killed_enemies += 1
	experience_gained(exp_reward)
	if killed_enemies == total_enemies:
		display_end_game_screen(true)

func experience_gained(exp_gain: int) -> void:
	if Playerdata.level == Leveldata.MAX_LEVEL:
		return
	var new_experience: int = Playerdata.experience + exp_gain
	if new_experience >= Leveldata.LEVEL_THRESHOLDS[Playerdata.level - 1]:
		level_up(new_experience)
	else:
		Playerdata.experience = new_experience

func level_up(new_experience: int) -> void:
	print("New level gained")
	new_experience -= Leveldata.LEVEL_THRESHOLDS[Playerdata.level - 1]
	Playerdata.level += 1
	Playerdata.experience = new_experience
	levelup.emit()

func display_end_game_screen(victorious: bool = false) -> void:
	get_tree().paused = true  # On pause aussi sur fin de partie
	var end_game_screen_scene: Control = end_game_screen_packed.instantiate()
	end_game_screen_scene.victorious = victorious
	var scene_handler: Node = get_node_or_null("/root/SceneHandler")
	if scene_handler:
		end_game_screen_scene.repeat_level.connect(scene_handler.new_game)
		end_game_screen_scene.main_menu.connect(scene_handler.load_main_menu)
	$UI.add_child(end_game_screen_scene)
	await get_tree().create_timer(0.4).timeout
	
	var player = get_tree().get_first_node_in_group("player")
	if player: player.process_mode = Node.PROCESS_MODE_DISABLED
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy: enemy.process_mode = Node.PROCESS_MODE_DISABLED
