extends Area2D

@export var ProjType: Resource
@export var ProjSpeed: int = 0
@export var ProjDamage: int = 0
@export var ProjKnockback: int = 0

@onready var player = get_parent().get_node("Player")
@onready var sprite = $Sprite2D
var movedir = Vector2()
var velocity = Vector2()

signal enemy_attacked

func change_proj():
	if Playerdata.Class == 0:
		ProjType = load("res://Player/Projectiles/Fireball.tres")
	if Playerdata.Class == 2:
		ProjType = load("res://Player/Projectiles/ThrowingKnive.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = player.position
	movedir = player.knockback_dir
	change_proj()
	sprite.texture = ProjType.image
	if player.knockback_dir.x != 0:
		sprite.rotation = 0
		sprite.scale.x = player.knockback_dir.x
	if player.knockback_dir.y == 1:
		sprite.rotation = 90
	if player.knockback_dir.y == -1:
		sprite.rotation = -90
	if player.knockback_dir.y == 0:
		sprite.scale.y = player.knockback_dir.y
	ProjSpeed = ProjType.Speed
	ProjKnockback = ProjType.Knockback
	ProjDamage = ProjType.Damage

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += movedir * delta * ProjSpeed

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		area.get_parent().knockback = player.knockback_dir * ProjKnockback
		area.get_parent().health -= ProjDamage
		emit_signal("enemy_attacked")
