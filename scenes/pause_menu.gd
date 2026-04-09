extends Control

signal resume_requested
signal main_menu_requested
signal quit_requested

func _ready() -> void:
	# On rend le menu toujours actif même quand le jeu est pausé
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	$VBoxContainer/ResumeButton.pressed.connect(func(): resume_requested.emit())
	$VBoxContainer/MainMenuButton.pressed.connect(func(): main_menu_requested.emit())
	$VBoxContainer/QuitButton.pressed.connect(func(): quit_requested.emit())
	
	# Optionnel : cacher au démarrage
	hide()
