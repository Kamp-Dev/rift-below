extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func touch(controls, index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	controls._input(event)
func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	var controls := Node2D.new()
	controls.set_script(load("res://touch_controls.gd"))
	controls.game = game
	root.add_child(controls)
	touch(controls, 0, Vector2(215, 608), true)
	assert(Input.get_action_strength("move_right") > 0.8)
	touch(controls, 1, Vector2(1000, 620), true)
	assert(Input.is_action_pressed("attack") and Input.is_action_pressed("move_right"))
	await physics_frame
	await physics_frame
	assert(game.player.attacking)
	touch(controls, 1, Vector2(1000, 620), false)
	assert(not Input.is_action_pressed("attack") and Input.is_action_pressed("move_right"))
	touch(controls, 0, Vector2(215, 608), false)
	assert(Input.get_vector("move_left", "move_right", "move_up", "move_down") == Vector2.ZERO)
	touch(controls, 2, Vector2(760, 700), true)
	await physics_frame
	await physics_frame
	touch(controls, 2, Vector2(760, 700), false)
	for i in range(40):
		await physics_frame
	assert(game.player.equipped_weapon.display_name == "Rift Cleaver")
	touch(controls, 0, Vector2(140, 550), true)
	touch(controls, 1, Vector2(1000, 620), true)
	controls.release_all()
	assert(not Input.is_action_pressed("attack") and not Input.is_action_pressed("move_up"))
	game.invulnerability = 0
	game.damage_player(999)
	touch(controls, 3, Vector2(576, 590), true)
	await physics_frame
	await physics_frame
	touch(controls, 3, Vector2(576, 590), false)
	assert(not game.dead)
	print("PASS: simultaneous touch movement and attack, independent releases, sword swap, focus reset, and restart")
	quit()
