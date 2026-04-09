extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var direction: Vector2 = Vector2.ZERO
var projectile_speed: float = 200.0
var projectile_damage: int = 25

func _ready() -> void:
	# Adaptation tutoriel : stats différentes selon classe (Mage = magie puissante)
	if Playerdata.Class == Playerdata.ClassChoice.Mage:
		projectile_speed = 300.0
		projectile_damage = 40  # plus fort pour la magie
	elif Playerdata.Class == Playerdata.ClassChoice.Thief:
		projectile_speed = 250.0
		projectile_damage = 30
	# Warrior ne passe jamais ici
	
	# Orientation du sprite selon direction
	if direction != Vector2.ZERO:
		sprite.rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * projectile_speed * delta

# Collision avec ennemis (groupe défini dans project.godot)
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		# Fallback robuste : si l'ennemi a une méthode ou une var health (comme slime_1.gd)
		if area.has_method("take_damage"):
			area.take_damage(projectile_damage)
		elif "health" in area:
			area.health -= projectile_damage
		queue_free()

# Destruction hors écran (connecté via VisibilityOnScreenEnabler2D)
func _on_screen_exited() -> void:
	queue_free()
