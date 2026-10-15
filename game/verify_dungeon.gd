extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var dungeon = load("res://main.tscn").instantiate()
	root.add_child(dungeon)
	await physics_frame
	assert(dungeon.rooms.size() == 9)
	assert(dungeon.distance_map.size() == dungeon.cells.size(), "Disconnected dungeon")
	var start: Vector2 = dungeon.player.position
	Input.action_press("move_right")
	for i in range(25):
		await physics_frame
	Input.action_release("move_right")
	assert(dungeon.player.position.x > start.x + 10, "Movement failed")
	var enemy = get_nodes_in_group("enemies")[0]
	enemy.position = dungeon.player.position + Vector2(65, 0)
	dungeon.player.update_facing(Vector2.RIGHT)
	enemy.speed = 0
	var before: int = enemy.health
	Input.action_press("attack")
	for i in range(16):
		await physics_frame
	Input.action_release("attack")
	assert(enemy.health < before, "Attack failed")
	for target in get_nodes_in_group("enemies"):
		target.hit(999, Vector2.ZERO)
	await physics_frame
	await physics_frame
	assert(get_nodes_in_group("enemies").is_empty())
	assert(dungeon.level > 1, "Level progression failed")
	dungeon.player.position = dungeon.exit_position
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	assert(dungeon.floor_number == 2, "Descent failed")
	assert(dungeon.distance_map.size() == dungeon.cells.size())
	dungeon.invulnerability = 0
	dungeon.damage_player(999)
	assert(dungeon.dead)
	Input.action_press("restart")
	await physics_frame
	await physics_frame
	Input.action_release("restart")
	assert(not dungeon.dead and dungeon.hp == 100 and dungeon.floor_number == 1)
	print("PASS: connected floors, movement, melee, XP, descent, death and restart")
	quit()


