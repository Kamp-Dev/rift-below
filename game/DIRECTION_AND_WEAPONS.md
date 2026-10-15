# Directional character and replaceable swords

The player uses a 4-column / 4-row walk atlas. Rows: south, west, east, north.
Each frame is 228 × 360 with transparent padding and a shared foot baseline.
Aim supports eight directions; the body uses the nearest cardinal view.
The last movement direction is retained while idle. Attacks lock direction
and the equipped weapon until their recovery ends. A requested sword change
is applied after the current swing. Each swing emits one impact at 38% of
its duration, so damage and the visible swing share the same aim and timing.

## Try the swords

1: Iron Sword — balanced (damage bonus 0, reach 105, swing 0.48 seconds)
2: Rift Cleaver — heavy (damage bonus 2, reach 125, swing 0.70 seconds)
3: Frostfang — fast (damage bonus 0, reach 95, swing 0.32 seconds)
These are freely selectable prototype equipment. Frostfang's name and color
are visual; no freezing status effect is implemented.

## Attach or replace a sword in Godot

Open Player in player.tscn. Select Player and change Equipped Weapon in the
Inspector to a RiftWeapon .tres resource. To create a new sword, duplicate a
resource in weapons/, then set its Texture, Display Name, Grip, Display Scale,
Damage Bonus, Reach, Attack Duration, and Trail Color. Drag a transparent
PNG or SVG into the project and assign it as Texture. The image must have its
blade pointing UP. Grip is the pixel coordinate where the hand holds the
texture. Existing textures use (24, 80); the texture is 48 × 96 pixels.

The WeaponSocket node is created by player.gd and appears under Player in
the Remote scene tree while running. It follows direction and swing progress.
The body animation never includes the sword texture. North-facing equipment
is drawn behind the body; other facings draw the sword in front.

Call player.equip_weapon(your_resource) for loot or inventory integration.
The WEAPONS array in player.gd defines the three hotkey choices; update it if
replacing one of the prototype hotkey slots with your own resource.

## Animation assets

The original side-view rift_juggernaut_walk.png is preserved. The new
rift_juggernaut_directional.png is generated from that visual reference with
the built-in image generation tool, then normalized to the runtime grid.
attacks/ contains built-in image_gen attack poses as single-row sheets,
228 × 360 pixels per frame, named south.png, west.png, east.png, north.png.
Attack poses use the same equipment attachment and normalized progress.
Godmode AI was tried for four directions; all requests failed with its
five-minute queue timeout. The installed attack assets use the built-in
image generator. The original generation records are retained in the local development project.

For a different body design or pose, adjust ATTACK_HANDS and hand coordinates in
player.gd update_visuals() to match its visible hand position.

## Verification

verify_dungeon.gd checks the core dungeon game loop.
verify_facing_weapons.gd checks eight aiming directions, body frame rows,
idle direction, locked attack direction, one damage event per swing, queued
weapon replacement, grip alignment, sword hotkeys, damage, and front/back hits.


