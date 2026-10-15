extends Node2D

const TILE := 64
const SIZE := Vector2i(43, 31)
const ENEMY = preload("res://dungeon_enemy.gd")
var cells: Dictionary = {}
var rooms: Array[Rect2i] = []
var walls: Node2D
var actors: Node2D
var player: CharacterBody2D
var camera: Camera2D
var hud: Label
var help_label: Label
var banner: Label
var weapon_label: Label
var floor_number: int = 1
var hp: int = 100
var max_hp: int = 100
var gold: int = 0
var xp: int = 0
var level: int = 1
var dead: bool = false
var invulnerability: float = 0.0
var attack_flash: float = 0.0
var slash_direction := Vector2.DOWN
var slash_reach: float = 105.0
var slash_color := Color.WHITE
var facing := Vector2.DOWN
var loot: Array[Dictionary] = []
var exit_position := Vector2.ZERO
var distance_map: Dictionary = {}
var path_timer: float = 0.0
var clock: float = 0.0
var message_timer: float = 0.0

func _ready() -> void:
	for entry in [["move_left", KEY_A, KEY_LEFT], ["move_right", KEY_D, KEY_RIGHT], ["move_up", KEY_W, KEY_UP], ["move_down", KEY_S, KEY_DOWN], ["attack", KEY_SPACE, KEY_J], ["interact", KEY_E, KEY_ENTER], ["restart", KEY_R]]:
		InputMap.add_action(entry[0])
		for key in entry.slice(1):
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(entry[0], event)
	for i in range(3):
		InputMap.add_action("weapon_%d" % i)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_1 + i
		InputMap.action_add_event("weapon_%d" % i, key)
	walls = Node2D.new()
	add_child(walls)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	player = preload("res://player.tscn").instantiate()
	player.max_speed = 235.0
	actors.add_child(player)
	player.attack_impact.connect(_perform_attack)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8
	player.add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := ColorRect.new()
	panel.color = Color("10151fee")
	panel.size = Vector2(1152, 112)
	canvas.add_child(panel)
	hud = Label.new()
	hud.position = Vector2(24, 12)
	hud.add_theme_font_size_override("font_size", 22)
	canvas.add_child(hud)
	help_label = Label.new()
	help_label.position = Vector2(24, 48)
	help_label.text = "WASD / Arrows  Move & aim     SPACE / J  Attack     1–3  Swap sword     E  Descend     R  Restart after death"
	help_label.modulate = Color("a2b2be")
	canvas.add_child(help_label)
	weapon_label = Label.new()
	weapon_label.position = Vector2(24, 78)
	weapon_label.modulate = Color("efcf8f")
	canvas.add_child(weapon_label)
	banner = Label.new()
	banner.position = Vector2(24, 710)
	banner.add_theme_font_size_override("font_size", 22)
	canvas.add_child(banner)
	if OS.has_feature("web") or DisplayServer.is_touchscreen_available() or "--touch-test" in OS.get_cmdline_user_args():
		var touch := Node2D.new()
		touch.set_script(preload("res://touch_controls.gd"))
		touch.game = self
		canvas.add_child(touch)
		help_label.text = "Left pad: move & aim    Hold ATTACK to swing    1–3: swords    EXIT: use an open portal"
		banner.position = Vector2(24, 126)
	generate_floor()

func center(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE) + Vector2.ONE * TILE / 2.0

func tile_at(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))

func carve(rect: Rect2i) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			cells[Vector2i(x, y)] = true

func generate_floor() -> void:
	for node in walls.get_children():
		node.free()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.free()
	cells.clear()
	rooms.clear()
	loot.clear()
	for gy in range(3):
		for gx in range(3):
			var room := Rect2i(2 + gx * 14 + randi_range(0, 1), 2 + gy * 10, randi_range(7, 10), randi_range(6, 8))
			rooms.append(room)
			carve(room)
			if rooms.size() > 1:
				var a := rooms[-2].get_center()
				var b := room.get_center()
				carve(Rect2i(mini(a.x, b.x), a.y, absi(a.x - b.x) + 2, 2))
				carve(Rect2i(b.x, mini(a.y, b.y), 2, absi(a.y - b.y) + 2))
	for x in range(SIZE.x + 1):
		for y in range(SIZE.y + 1):
			var cell := Vector2i(x, y)
			if cells.has(cell):
				continue
			var body := StaticBody2D.new()
			body.position = center(cell)
			var collision := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = Vector2.ONE * TILE
			collision.shape = shape
			body.add_child(collision)
			walls.add_child(body)
	player.position = center(rooms[0].get_center())
	player.velocity = Vector2.ZERO
	player.reset_pose()
	facing = player.facing_direction
	camera.limit_left = 0
	camera.limit_top = -84
	camera.limit_right = (SIZE.x + 1) * TILE
	camera.limit_bottom = (SIZE.y + 1) * TILE
	camera.reset_smoothing()
	exit_position = center(rooms[-1].get_center())
	for index in range(1, rooms.size()):
		var room := rooms[index]
		for count in range(1 + mini(floor_number, 3)):
			var enemy := CharacterBody2D.new()
			enemy.set_script(ENEMY)
			enemy.dungeon = self
			enemy.health = 2 + floor_number
			enemy.speed = 85 + mini(floor_number * 5, 40)
			enemy.position = center(Vector2i(randi_range(room.position.x + 1, room.end.x - 2), randi_range(room.position.y + 1, room.end.y - 2)))
			actors.add_child(enemy)
		loot.append({"pos": center(room.position + Vector2i(1, 1)), "type": "potion"})
	update_paths()
	announce("FLOOR %d — Defeat the guardians to open the cyan portal." % floor_number, 6)
	queue_redraw()

func update_paths() -> void:
	distance_map.clear()
	var origin := tile_at(player.position)
	distance_map[origin] = 0
	var queue: Array[Vector2i] = [origin]
	var index := 0
	while index < queue.size():
		var current := queue[index]
		index += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + offset
			if cells.has(next) and not distance_map.has(next):
				distance_map[next] = distance_map[current] + 1
				queue.append(next)

func chase_direction(pos: Vector2) -> Vector2:
	if pos.distance_to(player.position) > 650:
		return Vector2.ZERO
	var current := tile_at(pos)
	if current == tile_at(player.position):
		return pos.direction_to(player.position)
	var best := current
	var distance: int = distance_map.get(current, 9999)
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var next: Vector2i = current + offset
		if distance_map.get(next, 9999) < distance:
			best = next
			distance = distance_map[next]
	return pos.direction_to(center(best)) if best != current else Vector2.ZERO

func _physics_process(delta: float) -> void:
	clock += delta
	invulnerability = maxf(0, invulnerability - delta)
	attack_flash = maxf(0, attack_flash - delta)
	message_timer -= delta
	if message_timer <= 0:
		banner.text = ""
	if dead:
		if Input.is_action_just_pressed("restart"):
			dead = false
			hp = 100
			max_hp = 100
			level = 1
			xp = 0
			gold = 0
			floor_number = 1
			player.set_physics_process(true)
			player.reset_pose()
			player.equip_weapon(player.WEAPONS[0])
			generate_floor()
		return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.update_facing(movement)
	facing = player.facing_direction
	for i in range(3):
		if Input.is_action_just_pressed("weapon_%d" % i):
			player.equip_weapon(player.WEAPONS[i])
	player.modulate = Color("ff9284") if invulnerability > 0 and sin(clock * 35) > 0 else Color.WHITE
	path_timer -= delta
	if path_timer <= 0:
		path_timer = 0.35
		update_paths()
	if Input.is_action_pressed("attack"):
		player.begin_attack()
	for i in range(loot.size() - 1, -1, -1):
		if player.position.distance_to(loot[i].pos) < 42:
			if loot[i].type == "gold":
				gold += 5
			elif hp < max_hp:
				hp = mini(max_hp, hp + 30)
			else:
				continue
			loot.remove_at(i)
	if Input.is_action_just_pressed("interact") and player.position.distance_to(exit_position) < 85:
		if get_tree().get_nodes_in_group("enemies").is_empty():
			floor_number += 1
			hp = mini(max_hp, hp + 25)
			generate_floor()
		else:
			announce("The portal is sealed. Defeat the remaining guardians.", 3)
	hud.text = "RIFT BELOW    |    Floor %d    HP %d / %d    Lv %d    XP %d / %d    Gold %d    Guardians %d" % [floor_number, hp, max_hp, level, xp, level * 5, gold, get_tree().get_nodes_in_group("enemies").size()]
	var weapon: RiftWeapon = player.equipped_weapon
	weapon_label.text = "[1] Iron Sword    [2] Rift Cleaver    [3] Frostfang     |     %s  •  Damage %d  •  Reach %d  •  Swing %.2fs" % [weapon.display_name, 1 + level + weapon.damage_bonus, weapon.reach, weapon.attack_duration]
	queue_redraw()

func _perform_attack(direction: Vector2, weapon: RiftWeapon) -> void:
	if dead:
		return
	slash_direction = direction
	slash_reach = weapon.reach
	slash_color = weapon.trail_color
	attack_flash = 0.18
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var offset: Vector2 = enemy.position - player.position
		if offset.length() < weapon.reach and direction.dot(offset.normalized()) > 0.05:
			var ray := PhysicsRayQueryParameters2D.create(player.position, enemy.position, 1, [player.get_rid()])
			if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
				enemy.hit(1 + level + weapon.damage_bonus, offset.normalized())

func damage_player(amount: int) -> void:
	if invulnerability > 0 or dead:
		return
	hp = maxi(0, hp - amount)
	invulnerability = 0.85
	if hp == 0:
		dead = true
		player.set_physics_process(false)
		hud.text = "RIFT BELOW    |    FALLEN    Floor %d    Level %d    Gold %d" % [floor_number, level, gold]
		announce("The rift claims you. Press R to begin a new run.", 9999)

func enemy_defeated(pos: Vector2) -> void:
	loot.append({"pos": pos, "type": "gold"})
	xp += 1
	if xp >= level * 5:
		xp -= level * 5
		level += 1
		max_hp += 15
		hp = max_hp
		announce("LEVEL %d — Cleave strengthened. Health restored!" % level, 4)

func announce(text: String, seconds: float) -> void:
	banner.text = text
	message_timer = seconds

func _draw() -> void:
	draw_rect(Rect2(0, 0, (SIZE.x + 1) * TILE, (SIZE.y + 1) * TILE), Color("11121b"))
	for cell: Vector2i in cells:
		var rect := Rect2(Vector2(cell * TILE), Vector2.ONE * TILE)
		var shade := 0.12 + float(posmod(cell.x * 7 + cell.y * 13, 5)) * 0.008
		draw_rect(rect.grow(-1), Color(shade, shade + 0.018, shade + 0.03))
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not cells.has(cell + direction):
				var wall_pos := Vector2((cell + direction) * TILE)
				draw_rect(Rect2(wall_pos, Vector2.ONE * TILE).grow(-2), Color("303341"))
				draw_rect(Rect2(wall_pos + Vector2(3, 3), Vector2(58, 7)), Color("4b4954"))
	for room in rooms:
		var torch := center(room.position) + Vector2(0, -15)
		draw_circle(torch, 28 + sin(clock * 6) * 3, Color(1, 0.36, 0.08, 0.07))
		draw_circle(torch, 7 + sin(clock * 9), Color("ffaf56"))
	var opened := get_tree().get_nodes_in_group("enemies").is_empty()
	var portal_color := Color("65ecd5") if opened else Color("765282")
	draw_circle(exit_position, 35, Color(portal_color, 0.15))
	draw_arc(exit_position, 27 + sin(clock * 3) * 3, clock, clock + TAU * 0.85, 40, portal_color, 4)
	draw_string(ThemeDB.fallback_font, exit_position + Vector2(-32, 59), "E: DESCEND" if opened else "SEALED", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, portal_color)
	for item in loot:
		var pos: Vector2 = item.pos + Vector2(0, sin(clock * 4 + item.pos.x) * 3)
		if item.type == "gold":
			draw_circle(pos, 9, Color("ffca67"))
			draw_circle(pos, 5, Color("b97938"))
		else:
			draw_rect(Rect2(pos - Vector2(8, 10), Vector2(16, 22)), Color("cf596a"))
			draw_line(pos + Vector2(-5, 0), pos + Vector2(5, 0), Color.WHITE, 3)
			draw_line(pos + Vector2(0, -5), pos + Vector2(0, 5), Color.WHITE, 3)
	if is_instance_valid(player) and attack_flash > 0:
		var angle := slash_direction.angle()
		draw_arc(player.position, slash_reach, angle - 1.4, angle + 1.4, 28, Color(slash_color, attack_flash * 5), 7)
	# Compact dungeon map: gold marks the player, cyan marks the exit.
	var origin := camera.get_screen_center_position() + Vector2(405, -275)
	draw_rect(Rect2(origin - Vector2(7, 7), Vector2(146, 105)), Color("0b1018dd"))
	for cell: Vector2i in cells:
		draw_rect(Rect2(origin + Vector2(cell) * 3, Vector2.ONE * 3), Color("59616c"))
	draw_circle(origin + Vector2(tile_at(exit_position)) * 3, 3, portal_color)
	if is_instance_valid(player):
		draw_circle(origin + Vector2(tile_at(player.position)) * 3, 3, Color("ffcf79"))

