# BREACH — Bunker Entry

Open `project.godot` with Godot 4.7.2 or newer. The main scene is now **`scenes/entry_room_puzzle.tscn`**. Run that scene with **F6** in an already-open editor.

The playable puzzle adds F-key interactions, inventory (Tab/I), mouse-driven fuse installation, a 532 fuel lock, generator audio and power restoration, and the animated exit door. Read **[the full puzzle setup and script guide](docs/PUZZLE_SETUP.md)** for the node outline, Inspector assignments and state machine.

The original visual foundation remains in `scenes/entry_room.tscn`; the puzzle scene instances it, preserving your base room edits. Its ceiling breach is revised through editable overrides and new CSG nodes.

This is a local gameplay foundation for a four-player co-op horror game. The room, props, ceiling opening and materials are persistent editor resources. No script generates the level when you open or run it. Network sessions and replication remain for the later co-op pass.

## Walk through

Press **F6** on `entry_room_puzzle.tscn` (or **F5** for the main project). Click the game to capture the mouse, use **WASD** to walk, **F** to interact, **Tab/I** for inventory, and **Esc** to close a popup, cancel screwing or release the mouse. The original standalone room's old preview still uses H to hide its overlay.

## Edit visually — original base room

The Scene tree is organized by purpose:

| Group | What to change |
| --- | --- |
| `01_Atmosphere` | WorldEnvironment, the sole breach spotlight, and local dusty fog |
| `02_Architecture_CSG` | Floor, walls, columns and ceiling; edit CSG **Size** and **Transform** in the Inspector |
| `03_Collapsed_Breach` | Earth shaft, broken rim, rebar, roots and drifting dust |
| `04_Sealed_Bunker_Door` | Heavy door, frame, locking wheel and unpowered access panel |
| `05_Storage_and_Utilities` | Three shelving units, boxes, drum, crates, pipes and dead fixtures |
| `06_Debris_and_Age` | Rubble, papers, damp marks, planks, floor cracks and drain |
| `07_Coop_Spawn_Markers` | Four `Marker3D` transforms in the `coop_spawn_points` group |
| `08_Editor_Views` | Composition camera; select it for the Inspector preview, or enable **Cinematic Preview** from the viewport's **Perspective** menu |
| `09_PreviewPlayer_REMOVE_FOR_MULTIPLAYER` | Separate solo preview controller; replace with your eventual network player |

The room has about **9 × 7.6 m** of interior floor area and **4.1 m** of clear height. One Godot unit represents one metre. Walls, ceiling, floor, door and large props have collision enabled.

To resize the actual ceiling hole, expand `02_Architecture_CSG / Ceiling_Slab_EDIT_HOLE_CHILD`, then select `Breach_Cutter_SUBTRACTION`. Adjust **Radius** and **Transform**. The cutter uses CSG subtraction, so the opening updates in the viewport. Reposition `03_Collapsed_Breach` and the spotlight to match. The surface opening is approximately 7.8 m above the floor, with no climbable route back.

To inspect geometry in the dark, choose **Display Unshaded** from the viewport's **Perspective** menu, then return to **Display Normal** to judge lighting. Keep editor preview sun/environment disabled when checking atmosphere.

## Lighting and materials

In the original base room, the only light is `01_Atmosphere / Breach_Moonlight_ONLY_LIGHT`. In the playable puzzle scene, that spotlight is hidden and `BreachMoonlight` provides parallel moonlight through the irregular opening. Ambient illumination is disabled; SDFGI supplies light bounced from the same source. Generator indicators turn on during the puzzle, and room lights turn on only after starting the engine.

**Forward+ is required for volumetric fog and SDFGI.** Keep that renderer selected. The environment contains subtle global fog plus a local dust pocket under the breach; particles receive light and do not emit it. Changes to static geometry/lighting may need a short moment, camera movement, or toggling SDFGI to refresh the indirect lighting.

Editable materials are in `materials/`. The project includes its own seamless placeholder concrete, dirt, worn paint, rust and timber albedo/normal maps in `textures/`, with triplanar mapping so CSG can be resized easily. These are placeholders, suitable for blockout and lighting work.

## Scope and verification

Four player arrival markers are prepared. The entry-room puzzle, door interaction, inventory and placeholder generator audio are implemented in the puzzle scene. Multiplayer replication and sessions are deferred.

The project was loaded and rendered with Godot 4.7.2, Forward+ and an NVIDIA RTX 2060. Checks cover the single-light setup, editable CSG shapes, four markers, wall/floor/door/ceiling collisions, the continuous ceiling opening, and the solo preview player's floor contact.

Reference: [Godot volumetric fog documentation](https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html) and [Godot CSG documentation](https://docs.godotengine.org/en/stable/tutorials/3d/csg_tools.html).
