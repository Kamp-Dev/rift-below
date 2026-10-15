# Rift Below

[Play in your browser](https://Kamp-Dev.github.io/rift-below/)

A Godot 4.7.2 dungeon crawler starring the Rift Juggernaut, with directional
walk and attack animations, replaceable swords, enemies, loot, and leveling.

## Mobile
Open the play link in a modern browser, then turn your phone sideways.
Use the left pad to move and aim, hold ATTACK to swing, and tap 1/2/3 to equip
swords. EXIT enters the next floor after every guardian is defeated.
RETRY starts another run after death. No installation or account is required.

## Desktop
WASD/arrow keys move, Space/J attacks, 1–3 equips swords, E uses the portal,
and R restarts after death.

## Project
`game/project.godot` is the editable Godot project. `docs/` is the tested,
single-threaded Web export served through GitHub Pages. The renderer is
Compatibility/WebGL 2. No cross-origin isolation headers are needed.

To rebuild with Godot 4.7.2 and its official export templates installed:

```sh
godot --headless --editor --path game --import --quit
godot --headless --editor --path game --script ../tools/export_web.gd
```

See `game/DIRECTION_AND_WEAPONS.md` to replace sword textures and stats.
Verification scripts in `game/` cover the dungeon loop, facing/weapons, and
multitouch controls. Browser compatibility still depends on the device's
WebGL 2 support; desktop Chrome has been checked, not physical mobile hardware.

## Artwork
Character art is AI-generated from the supplied Rift Juggernaut reference.
Walk and attack views were generated with OpenAI image generation. Sword and
dungeon graphics are code-authored. Godmode animation attempts timed out;
no Godmode output is used in this build. Godot is distributed under the MIT
license; see https://godotengine.org/license/.
