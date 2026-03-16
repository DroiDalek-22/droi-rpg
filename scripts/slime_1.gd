# Change the motion mode of the character from grounded to floating to prevent the character from sticking into the player
extends CharacterBody2D

signal died(exp : int)

@export_category("Stats")
@export var exp_reward: int = 600
@export_category("Related Scenes")
@export var death_packed : PackedScene

# A ajouter, animation de mort
const speed = 40
var player_chase = false
var player = null


var health = 60
var player_inattack_zone = false
var can_take_damage = true

func _ready() -> void:
	add_to_group("enemies")  # Au cas où pas ajouté dans l'éditeur (utile pour instances runtime)
	
	# Auto-connexion à game_scene (ajoute le groupe "game_scene" sur ton node game_scene dans l'éditeur)
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene and has_signal("died"):
		died.connect(game_scene.enemy_died)

func _physics_process(delta):
	deal_with_damage() 
	update_health()
	
	if player_chase:
		if position.distance_to(player.position) > 10:  # To prevent the character from pushing the player when he's idle
			var direction = (player.position - position).normalized()  # Normalize for constant speed
			velocity = direction * speed  # Use velocity for physical movement
			if abs(direction.x) > abs(direction.y):
				$AnimatedSprite2D.play("side_walk")
				$AnimatedSprite2D.flip_h = direction.x < 0
			elif direction.y > 0:
				$AnimatedSprite2D.play("front_walk")
			else:
				$AnimatedSprite2D.play("back_walk")
		else:
			# When too close : stop and play idle (added to prevent animation freeze)
			velocity = Vector2.ZERO
			$AnimatedSprite2D.play("front_idle")
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("front_idle")
	
	move_and_slide()  # Added at the end to make the character collide with it's environment
	


func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	player = null
	player_chase = false
 
func enemy():
	pass

func _on_slime_1_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = true


func _on_slime_1_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = false
		
func deal_with_damage():
	if player_inattack_zone and global.player_current_attack == true:
		if can_take_damage == true:
			health -= 20
			$take_damage_cooldown.start()
			can_take_damage = false
			print("slime health = ", health)
			if health <= 0:
				death()


func _on_take_damage_cooldown_timeout() -> void:
	can_take_damage = true
	
func death() -> void:
	remove_from_group("enemies")  # Retrait immédiat du groupe
	died.emit(exp_reward)
	var death_scene : Node2D = death_packed.instantiate()
	died.emit(exp_reward)
	death_scene.position = global_position + Vector2(0.0,-32.0)
	%Effects.add_child(death_scene)
	queue_free()

func update_health():
	var healthbar = $HealthBar
	healthbar.value = health
	if health >= 60:
		healthbar.visible = false
	else:
		healthbar.visible = true

func _on_slime_1_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Projectile"):
		var proj = get_parent().get_node("Projectile")
		if proj != null:
			proj.enemy_attacked.connect(update_health())
