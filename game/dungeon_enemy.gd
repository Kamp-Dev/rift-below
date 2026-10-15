extends CharacterBody2D

var dungeon: Node2D
var health: int = 3
var speed: float = 95.0
var hurt: float = 0.0
var phase: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	collider.shape = shape
	add_child(collider)

func _physics_process(delta: float) -> void:
	phase += delta * 5.0
	hurt = maxf(0.0, hurt - delta)
	if dungeon.dead:
		return
	var direction: Vector2 = dungeon.chase_direction(global_position)
	velocity = direction * speed
	move_and_slide()
	if global_position.distance_to(dungeon.player.global_position) < 48.0:
		dungeon.damage_player(12)
	queue_redraw()

func hit(damage: int, direction: Vector2) -> void:
	health -= damage
	hurt = 0.18
	move_and_collide(direction * 18.0)
	if health <= 0:
		dungeon.enemy_defeated(global_position)
		queue_free()

func _draw() -> void:
	draw_set_transform(Vector2(0, 17), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 22, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2(0, sin(phase) * 3))
	var color := Color("b8ffda") if hurt > 0 else Color("48786b")
	draw_colored_polygon(PackedVector2Array([Vector2(-21, 16), Vector2(-17, -10), Vector2(0, -28), Vector2(17, -10), Vector2(21, 16), Vector2(0, 10)]), color)
	draw_circle(Vector2(-7, -6), 4, Color("e8fa8c"))
	draw_circle(Vector2(7, -6), 4, Color("e8fa8c"))
	draw_line(Vector2(-9, 4), Vector2(9, 4), Color("142a2d"), 3)
	draw_set_transform(Vector2.ZERO)
	for i in range(health):
		draw_rect(Rect2(-15 + i * 11, -38, 8, 3), Color("ef9077"))
