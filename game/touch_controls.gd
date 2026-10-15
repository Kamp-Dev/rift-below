extends Node2D

var game: Node2D
var stick_finger: int = -1
var stick_vector := Vector2.ZERO
var held_buttons: Dictionary = {}
const STICK_CENTER := Vector2(140, 608)
const STICK_RADIUS := 82.0
var buttons := {
	"attack": {"center": Vector2(1000, 620), "radius": 70.0, "label": "ATTACK"},
	"interact": {"center": Vector2(1060, 462), "radius": 48.0, "label": "EXIT"},
	"weapon_0": {"center": Vector2(670, 700), "radius": 44.0, "label": "1"},
	"weapon_1": {"center": Vector2(760, 700), "radius": 44.0, "label": "2"},
	"weapon_2": {"center": Vector2(850, 700), "radius": 44.0, "label": "3"},
	"restart": {"center": Vector2(576, 590), "radius": 65.0, "label": "RETRY"}
}

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()

func release_all() -> void:
	stick_finger = -1
	set_stick(Vector2.ZERO)
	for action in held_buttons.values():
		Input.action_release(action)
	held_buttons.clear()
	queue_redraw()

func set_stick(value: Vector2) -> void:
	stick_vector = value.limit_length(1.0)
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	if stick_vector.length() > 0.14:
		var strength := (stick_vector.length() - 0.14) / 0.86
		var direction := stick_vector.normalized() * strength
		Input.action_press("move_left" if direction.x < 0 else "move_right", absf(direction.x))
		Input.action_press("move_up" if direction.y < 0 else "move_down", absf(direction.y))
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(STICK_CENTER) < 118 and stick_finger == -1 and not game.dead:
				stick_finger = event.index
				set_stick((event.position - STICK_CENTER) / STICK_RADIUS)
				get_viewport().set_input_as_handled()
				return
			for action in buttons:
				if (action == "restart") != game.dead:
					continue
				if event.position.distance_to(buttons[action].center) <= buttons[action].radius:
					held_buttons[event.index] = action
					Input.action_press(action)
					get_viewport().set_input_as_handled()
					queue_redraw()
					return
		else:
			if event.index == stick_finger:
				stick_finger = -1
				set_stick(Vector2.ZERO)
			if held_buttons.has(event.index):
				var action: String = held_buttons[event.index]
				held_buttons.erase(event.index)
				if not held_buttons.values().has(action):
					Input.action_release(action)
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == stick_finger:
		set_stick((event.position - STICK_CENTER) / STICK_RADIUS)
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game):
		return
	if not game.dead:
		draw_circle(STICK_CENTER, STICK_RADIUS, Color(0.03, 0.06, 0.1, 0.55))
		draw_arc(STICK_CENTER, STICK_RADIUS, 0, TAU, 64, Color(0.8, 0.87, 0.95, 0.55), 3, true)
		draw_circle(STICK_CENTER + stick_vector * 57, 30, Color(0.8, 0.87, 0.95, 0.55))
	for action in buttons:
		if (action == "restart") != game.dead:
			continue
		var button: Dictionary = buttons[action]
		var active: bool = held_buttons.values().has(action)
		var color := Color("efb36a") if active else Color("c5d3df")
		draw_circle(button.center, button.radius, Color(0.08, 0.12, 0.18, 0.75))
		draw_arc(button.center, button.radius, 0, TAU, 48, color, 3, true)
		var font := ThemeDB.fallback_font
		var text_size := font.get_string_size(button.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		draw_string(font, button.center - Vector2(text_size.x / 2, -7), button.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)

