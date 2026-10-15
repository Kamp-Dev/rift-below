extends CharacterBody2D

signal attack_impact(direction: Vector2, weapon: RiftWeapon)
signal weapon_changed(weapon: RiftWeapon)

const WALK: Texture2D = preload("res://rift_juggernaut_directional.png")
# Hand positions measured in each 228x360 attack cell, before display scaling.
const ATTACK_HANDS := [
	[Vector2(36, 90), Vector2(42, 145), Vector2(119, 160), Vector2(34, 202)],
	[Vector2(202, 96), Vector2(193, 127), Vector2(26, 182), Vector2(147, 231)],
	[Vector2(31, 95), Vector2(65, 145), Vector2(194, 180), Vector2(93, 230)],
	[Vector2(198, 80), Vector2(197, 99), Vector2(39, 152), Vector2(181, 202)]
]
const WEAPONS: Array[RiftWeapon] = [preload("res://weapons/iron_sword.tres"), preload("res://weapons/rift_cleaver.tres"), preload("res://weapons/frostfang.tres")]
@export var max_speed: float = 235.0
@export var acceleration: float = 1800.0
@export var friction: float = 1500.0
@export var walk_cycles_per_sec: float = 1.45
@export var base_scale: Vector2 = Vector2(0.24, 0.24)
@export var equipped_weapon: RiftWeapon = preload("res://weapons/iron_sword.tres")
var facing_direction := Vector2.DOWN
var facing_row: int = 0
var attacking: bool = false
var attack_direction := Vector2.DOWN
var attack_elapsed: float = 0.0
var attack_weapon: RiftWeapon
var pending_weapon: RiftWeapon
var impact_sent: bool = false
var walk_phase: float = 0.0
var idle_time: float = 0.0
var stride: float = 0.0
var last_step: int = -1
var footprints: Array[Dictionary] = []
var attack_textures: Array[Texture2D] = []
var attack_frame_counts: Array[int] = []
var weapon_socket: Node2D
var weapon_sprite: Sprite2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_blend: Sprite2D = $SpriteBlend2D

func _ready() -> void:
	weapon_socket = Node2D.new()
	weapon_socket.name = "WeaponSocket"
	add_child(weapon_socket)
	weapon_sprite = Sprite2D.new()
	weapon_sprite.name = "EquippedSword"
	weapon_sprite.centered = false
	weapon_socket.add_child(weapon_sprite)
	equip_weapon(equipped_weapon)
	# Directional body animations. Weapon textures stay separate.
	for direction in ["south", "west", "east", "north"]:
		var path := "res://attacks/%s.png" % direction
		if ResourceLoader.exists(path):
			var texture: Texture2D = load(path)
			attack_textures.append(texture)
			attack_frame_counts.append(texture.get_width() / 228)
		else:
			attack_textures.append(null)
			attack_frame_counts.append(0)
	update_facing(Vector2.DOWN)
	update_visuals()

func update_facing(direction: Vector2) -> void:
	if attacking or direction.length_squared() < 0.01:
		return
	facing_direction = direction.normalized()
	if absf(direction.x) > absf(direction.y):
		facing_row = 2 if direction.x > 0 else 1
	else:
		facing_row = 0 if direction.y > 0 else 3

func equip_weapon(weapon: RiftWeapon) -> void:
	if weapon == null:
		return
	if attacking:
		pending_weapon = weapon
		return
	equipped_weapon = weapon
	if is_instance_valid(weapon_sprite):
		weapon_sprite.texture = weapon.texture
		weapon_sprite.offset = -weapon.grip
		weapon_sprite.scale = Vector2.ONE * weapon.display_scale
	weapon_changed.emit(weapon)

func begin_attack() -> bool:
	if attacking:
		return false
	attacking = true
	attack_direction = facing_direction
	attack_weapon = equipped_weapon
	attack_elapsed = 0.0
	impact_sent = false
	return true

func reset_pose() -> void:
	attacking = false
	attack_elapsed = 0
	velocity = Vector2.ZERO
	walk_phase = 0
	footprints.clear()
	pending_weapon = null
	update_facing(Vector2.DOWN)
	update_visuals()

func _physics_process(delta: float) -> void:
	idle_time += delta
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	update_facing(movement)
	var target := movement * max_speed * (0.38 if attacking else 1.0)
	velocity = velocity.move_toward(target, (acceleration if movement.length_squared() > 0.01 else friction) * delta)
	move_and_slide()
	stride = lerpf(stride, clampf(velocity.length() / max_speed, 0, 1), minf(delta * 10, 1))
	if stride > 0.04 and not attacking:
		walk_phase = fmod(walk_phase + delta * walk_cycles_per_sec * 4.0 * maxf(0.5, stride), 4.0)
		var step := int(walk_phase / 2.0)
		if step != last_step:
			last_step = step
			var side := facing_direction.orthogonal() * (-9 if step == 0 else 9)
			footprints.append({"pos": global_position + Vector2(0, 25) + side, "life": 1.2})
	else:
		walk_phase = 0
		last_step = -1
	for i in range(footprints.size() - 1, -1, -1):
		footprints[i].life -= delta
		if footprints[i].life <= 0:
			footprints.remove_at(i)
	if attacking:
		attack_elapsed += delta
		if not impact_sent and attack_elapsed >= attack_weapon.attack_duration * 0.38:
			impact_sent = true
			attack_impact.emit(attack_direction, attack_weapon)
		if attack_elapsed >= attack_weapon.attack_duration:
			attacking = false
			if pending_weapon != null:
				var next := pending_weapon
				pending_weapon = null
				equip_weapon(next)
	update_visuals()
	queue_redraw()

func update_visuals() -> void:
	var frame_a := int(walk_phase) % 4
	var frame_b := (frame_a + 1) % 4
	var fraction := smoothstep(0.0, 1.0, fmod(walk_phase, 1.0))
	var texture := WALK
	var columns := 4
	var rows := 4
	var frame := facing_row * 4 + frame_a
	var next_frame := facing_row * 4 + frame_b
	var progress := attack_elapsed / attack_weapon.attack_duration if attacking else 0.0
	var has_attack := attacking and attack_textures.size() == 4 and attack_textures[facing_row] != null
	if has_attack:
		texture = attack_textures[facing_row]
		columns = attack_frame_counts[facing_row]
		rows = 1
		frame = mini(int(progress * columns), columns - 1)
		next_frame = frame
		fraction = 0.0
	var bob := sin(walk_phase * PI) * 1.2 * stride if not attacking else 0.0
	var lunge := sin(progress * PI) * 4.0 if attacking else 0.0
	for visual: Sprite2D in [sprite, sprite_blend]:
		visual.texture = texture
		visual.frame = 0
		visual.hframes = columns
		visual.vframes = rows
		visual.flip_h = false
		visual.scale = base_scale * Vector2(1 + sin(idle_time * 2.4) * 0.008, 1.0)
		visual.position = Vector2(0, -15 + bob) + (attack_direction * lunge if attacking else Vector2.ZERO)
		visual.rotation = sin(progress * TAU) * 0.045 if attacking and not has_attack else 0.0
	sprite.frame = frame
	sprite_blend.frame = next_frame
	sprite_blend.modulate.a = fraction * 0.32 * stride if not attacking else 0.0
	var hand: Vector2 = [Vector2(-17, -5), Vector2(-14, -4), Vector2(14, -4), Vector2(17, -9)][facing_row]
	if has_attack:
		hand = (ATTACK_HANDS[facing_row][mini(frame, 3)] - Vector2(114, 180)) * base_scale + Vector2(0, -15) + attack_direction * lunge
	weapon_socket.position = hand + Vector2(0, bob)
	weapon_socket.z_index = 0
	move_child(weapon_socket, 0 if facing_row == 3 else get_child_count() - 1)
	# Separate grip pivot: any replacement sword follows the same swing.
	var aim := attack_direction if attacking else facing_direction
	var rest_angle := aim.angle() + PI / 2.0 - 0.45
	var swing := 0.0
	if attacking:
		if progress < 0.2:
			swing = lerpf(-0.45, -1.35, progress / 0.2)
		elif progress < 0.58:
			swing = lerpf(-1.35, 1.45, smoothstep(0.2, 0.58, progress))
		else:
			swing = lerpf(1.45, -0.45, smoothstep(0.58, 1.0, progress))
		if not has_attack:
			weapon_socket.position += attack_direction * sin(progress * PI) * 10
		weapon_socket.rotation = aim.angle() + PI / 2.0 + swing
	else:
		weapon_socket.rotation = rest_angle

func _draw() -> void:
	for footprint in footprints:
		draw_set_transform(footprint.pos - global_position, 0, Vector2(1, 0.45))
		draw_circle(Vector2.ZERO, 7, Color(1, 0.35, 0.07, footprint.life * 0.2))
	draw_set_transform(Vector2(0, 25), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 24, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO)
	# Ground chevron makes the exact diagonal attack aim readable too.
	var tip := facing_direction * 36 + Vector2(0, 25)
	var side := facing_direction.orthogonal() * 5
	draw_polyline(PackedVector2Array([tip - facing_direction * 7 + side, tip, tip - facing_direction * 7 - side]), equipped_weapon.trail_color * Color(1, 1, 1, 0.65), 2, true)

