extends Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	change_scenes()


func _on_cliffside_exit_point_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		global.transition_scene = true

func change_scenes():
	if global.transition_scene == true:
		if global.current_scene == "cliffside":
			get_tree().change_scene_to_file("res://scenes/world.tscn")
			global.finish_changescenes()
