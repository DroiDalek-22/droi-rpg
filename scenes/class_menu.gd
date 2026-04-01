extends Control

# Connecte ces fonctions aux boutons dans l'éditeur
func _on_mage_button_pressed():
	choose_class(0)

func _on_warrior_button_pressed():
	choose_class(1)

func _on_thief_button_pressed():
	choose_class(2)

func choose_class(class_index: int):
	match class_index:
		0:
			Playerdata.Class = Playerdata.ClassChoice.Mage
		1:
			Playerdata.Class = Playerdata.ClassChoice.Warrior
		2:
			Playerdata.Class = Playerdata.ClassChoice.Thief
	
	# Change vers ta scène de jeu principale (adapte si nécessaire)
	get_tree().change_scene_to_file("res://scenes/world.tscn")
	# Ou "res://scenes/game_scene.tscn" / utilise scene_handler si tu préfères
