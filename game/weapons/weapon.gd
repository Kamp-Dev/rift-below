extends Resource
class_name RiftWeapon

@export var display_name: String = "Iron Sword"
@export var texture: Texture2D
# Pixel coordinates of the hand grip in the texture; the blade points up.
@export var grip: Vector2 = Vector2(24, 80)
@export var display_scale: float = 0.72
@export var damage_bonus: int = 0
@export var reach: float = 105.0
@export var attack_duration: float = 0.48
@export var trail_color: Color = Color("e4c98a")
