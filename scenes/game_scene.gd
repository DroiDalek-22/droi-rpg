extends Node2D

signal levelup

@export var end_game_screen_packed: PackedScene

@onready var HUD: Control = $UI/HUD

func _ready() -> void:
	# Plus besoin de compter ici – les ennemis s'auto-connectent
	# (mais pour debug initial, tu peux print get_tree().get_nodes_in_group("enemies").size())
	print("Ennemis au start : ", get_tree().get_nodes_in_group("enemies").size())
	
	var player = get_tree().get_first_node_in_group("player")
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if player == null:
		push_error("game_scene.gd : Aucun joueur trouvé dans le groupe 'player'. Vérifie le groupe sur le nœud joueur.")
		return

	if player.has_method("calculates_stats"):
		levelup.connect(player.calculates_stats)
	else:
		push_warning("game_scene.gd : Le joueur n'a pas la méthode calculates_stats()")

	if player.has_signal("game_over"):
		player.game_over.connect(display_end_game_screen)
	else:
		push_warning("game_scene.gd : Le joueur n'a pas le signal 'game_over'")

	# Ajoute-toi au groupe pour que les ennemis te trouvent
	add_to_group("game_scene")
	player.update_hp_bar.connect(HUD.update_hp_bar)

func enemy_died(exp_reward: int) -> void:
	experience_gained(exp_reward)
	
	# Check dynamique pour victoire (après mort, car remove_from_group déjà fait)
	if get_tree().get_nodes_in_group("enemies").is_empty():
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
	HUD.update_level_indicator()

func display_end_game_screen(victorious: bool = false) -> void:
	var end_game_screen_scene: Control = end_game_screen_packed.instantiate()
	end_game_screen_scene.victorious = victorious
	
	var scene_handler: Node = get_node_or_null("/root/SceneHandler")
	if scene_handler:
		end_game_screen_scene.repeat_level.connect(scene_handler.new_game)
		end_game_screen_scene.main_menu.connect(scene_handler.load_main_menu)
	else:
		push_error("game_scene.gd : SceneHandler introuvable à /root/SceneHandler")
	
	$UI.add_child(end_game_screen_scene)
	await get_tree().create_timer(0.4).timeout
	
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
	if player:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for enemy: CharacterBody2D in enemies:
		if enemy:
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
