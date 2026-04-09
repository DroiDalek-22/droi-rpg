extends CharacterBody2D

signal game_over(victorious : bool)
signal update_hp_bar(hp_bar_value: int)

@export_category("Stats")
@export var speed: int = 40

@onready var Projectile = preload("res://scenes/Projectiles/projectile.tscn")

var move_direction: Vector2 = Vector2.ZERO

# Définition des variables
var enemy_inattack_range = false
var enemy_attack_cooldown = true
var health = 100
var player_alive = true

var attack_ip = false
var attack_speed: float

var current_dir = "none"
var hitpoints_max: int

func _ready() -> void:
	hitpoints_max = health
	$AnimatedSprite2D.play("front_idle")
	calculate_stats()

func _physics_process(delta):
	player_movement(delta)
	enemy_attack()
	attack()
	update_health()
	movement_loop()
	
	if health <= 0:
		$AnimatedSprite2D.play("death")
		player_alive = false
		health = 0
		print("player has been killed")
		self.queue_free() 

func player_movement(delta):
	if Input.is_action_pressed("right"):
		current_dir = "right"
		play_anim(1)
		velocity.x = speed
		velocity.y = 0
	elif Input.is_action_pressed("left"):
		current_dir = "left"
		play_anim(1)
		velocity.x = -speed
		velocity.y = 0
	elif Input.is_action_pressed("up"):
		current_dir = "up"
		play_anim(1)
		velocity.x = 0
		velocity.y = -speed
	elif Input.is_action_pressed("down"):
		current_dir = "down"
		play_anim(1)
		velocity.x = 0
		velocity.y = speed
	else :
		play_anim(0)
		velocity.x = 0
		velocity.y = 0
	
	move_and_slide()

func calculate_stats() -> void:
	attack_speed = equations.calculate_attack_speed()
	print("my new attack speed ", attack_speed)

func movement_loop() -> void:
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	var motion: Vector2 = move_direction.normalized() * speed
	set_velocity(motion)
	move_and_slide() 

func play_anim(movement):
	var dir = current_dir
	var anim = $AnimatedSprite2D
	
	if dir == "right":
		anim.flip_h = false
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("side_idle")
	elif dir == "left":
		anim.flip_h = true
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("side_idle")
	elif dir == "up":
		if movement == 1:
			anim.play("back_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("back_idle")
	elif dir == "down":
		if movement == 1:
			anim.play("front_walk")
		elif movement == 0:
			if attack_ip == false:
				anim.play("front_idle")

func attack():
	var dir = current_dir
	
	if Input.is_action_just_pressed("attack") and not attack_ip:
		global.player_current_attack = true
		attack_ip = true
		
		if Playerdata.Class == Playerdata.ClassChoice.Warrior:
			# Attaque mêlée classique (conservée)
			if dir == "right":
				$AnimatedSprite2D.flip_h = false
				$AnimatedSprite2D.play("side_attack")
				$deal_attack_timer.start()
			elif dir == "left":
				$AnimatedSprite2D.flip_h = true
				$AnimatedSprite2D.play("side_attack")
				$deal_attack_timer.start()
			elif dir == "up":
				$AnimatedSprite2D.play("back_attack")
				$deal_attack_timer.start()
			elif dir == "down":
				$AnimatedSprite2D.play("front_attack")
				$deal_attack_timer.start()
		else:
			# Attaque distance (Mage/Thief) – projectile
			$AnimatedSprite2D.play("side_attack")  # ou "cast" si tu ajoutes l'anim
			var proj = Projectile.instantiate()
			get_parent().add_child(proj)
			proj.position = global_position
			
			# Direction selon facing
			match dir:
				"right": proj.direction = Vector2.RIGHT
				"left": proj.direction = Vector2.LEFT
				"up": proj.direction = Vector2.UP
				"down": proj.direction = Vector2.DOWN
			
			$deal_attack_timer.start()  # réutilisé pour la durée d'animation
		
		# global.player_current_attack reste true seulement pour Warrior (melee)

func _on_deal_attack_timer_timeout() -> void:
	$deal_attack_timer.stop()
	global.player_current_attack = false
	attack_ip = false

# Le reste du fichier reste IDENTIQUE (enemy_attack, update_health, death, etc.)
func player():
	pass

func _on_player_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_inattack_range = true

func _on_player_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_inattack_range = false

func enemy_attack():
	if enemy_inattack_range and enemy_attack_cooldown == true:
		health -= 10
		enemy_attack_cooldown = false
		$attack_cooldown.start()
		print(health)

func _on_attack_cooldown_timeout() -> void:
	enemy_attack_cooldown = true

func update_health():
	var healthbar = $HealthBar
	healthbar.value = health
	if health >= 100:
		healthbar.visible = false
	else:
		healthbar.visible = true

func _on_regin_timer_timeout() -> void:
	if health < 100:
		health += 20
		if health > 100:
			health = 100
	@warning_ignore("integer_division")
	update_hp_bar.emit((health * 100) / hitpoints_max)
	if health <= 0:
		health = 0
		death()

func death() -> void:
	game_over.emit(false)
