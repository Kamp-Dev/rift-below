extends SceneTree
var impacts: Array = []
func _initialize() -> void:
	call_deferred("verify")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
func verify() -> void:
	var dungeon = load("res://main.tscn").instantiate()
	root.add_child(dungeon)
	await physics_frame
	var player = dungeon.player
	check(player.attack_textures.size() == 4, "Missing directional attacks")
	for texture in player.attack_textures:
		check(texture != null and texture.get_width() == 912 and texture.get_height() == 360, "Attack atlas was not loaded")
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	player.attack_impact.connect(func(direction, weapon): impacts.append([direction, weapon]))
	var directions := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]
	for direction in directions:
		player.reset_pose()
		player.update_facing(direction)
		player.update_visuals()
		var expected_row := 2 if direction.x > 0 else 1
		if absf(direction.y) >= absf(direction.x):
			expected_row = 0 if direction.y > 0 else 3
		check(player.facing_row == expected_row, "Wrong direction row")
		check(int(player.sprite.frame / 4) == expected_row, "Body did not turn")
		player.update_facing(Vector2.ZERO)
		check(player.facing_direction.is_equal_approx(direction.normalized()), "Idle lost facing")
		player.begin_attack()
		player.update_facing(-direction)
		check(player.attack_direction.is_equal_approx(direction.normalized()), "Attack changed direction mid swing")
		var before := impacts.size()
		for i in range(35):
			await physics_frame
		check(impacts.size() == before + 1, "Attack impact must fire once")
		check(impacts[-1][0].is_equal_approx(direction.normalized()), "Damage aim differs from facing")
	player.reset_pose()
	player.equip_weapon(player.WEAPONS[0])
	player.begin_attack()
	player.equip_weapon(player.WEAPONS[1])
	check(player.equipped_weapon == player.WEAPONS[0], "Sword changed during a swing")
	for i in range(35):
		await physics_frame
	check(player.equipped_weapon == player.WEAPONS[1], "Queued swap did not equip")
	check(player.weapon_sprite.texture == player.WEAPONS[1].texture, "Replacement texture did not attach")
	check(player.weapon_sprite.offset == -player.WEAPONS[1].grip, "Sword pivot lost grip alignment")
	# Keep a target in front and one behind; only the front may take damage.
	player.reset_pose()
	player.position = dungeon.center(dungeon.rooms[0].get_center())
	player.update_facing(Vector2.RIGHT)
	var front = get_nodes_in_group("enemies")[0]
	var back = get_nodes_in_group("enemies")[1]
	front.health = 50
	back.health = 50
	front.position = player.position + Vector2(65, 0)
	back.position = player.position - Vector2(65, 0)
	player.begin_attack()
	for i in range(48):
		await physics_frame
	check(front.health == 46, "Equipped cleaver damage was not used")
	check(back.health == 50, "Attack hit a target behind the character")
	for index in range(3):
		Input.action_press("weapon_%d" % index)
		await physics_frame
		await physics_frame
		Input.action_release("weapon_%d" % index)
		check(player.equipped_weapon == player.WEAPONS[index], "Sword hotkey failed")
	print("PASS: 8-way aim, 4 body directions, idle facing, locked attacks, single impact, queued swaps, grip attachment, sword stats and hotkeys")
	quit()
