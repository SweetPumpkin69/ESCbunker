# Entry Room puzzle — implementation and Inspector guide

Run **`scenes/entry_room_puzzle.tscn`** with **F6**. It is also the project's new main scene for F5. If an already-open editor retains the previous main scene setting, open this scene and use F6, or reload the project after saving your work.

**Controls:** click to capture the mouse; WASD walk; **F** interact; **Tab** or **I** inventory; **Esc** close a popup, cancel installation, or release the mouse. Home is not used.

## Your existing room and the revised breach

`entry_room_puzzle.tscn` instances `entry_room.tscn` as `Room`. The original room file and original preview script are preserved. Changes you save to the base room continue to appear through that instance, except for the explicitly overridden breach, original preview player, and door display.

The cylindrical earth shaft is hidden and its collision is disabled in the puzzle scene. A new **CSGPolygon3D subtraction** makes an asymmetric ceiling opening. Broken concrete edge fragments, shallow earth pockets, bent rebar and exposed roots surround it. There is no tall cylindrical collar. The new pieces are ordinary saved CSG nodes, with no runtime level generation.

Edit the opening at:

`Room / 02_Architecture_CSG / Ceiling_Slab_EDIT_HOLE_CHILD / Jagged_Breach_SUBTRACTION`

Edit its dressing in `Breach_Revision_CSG`. The `Room` instance and nested legacy player have **Editable Children** enabled. The old cylinder and circular cut remain hidden overrides so the base room can still be used separately.

`BreachMoonlight` is a shadow-casting DirectionalLight3D so the opening's irregular silhouette shapes a shaft and a floor pool. It is the only active light initially; the original spotlight is hidden. SDFGI supplies bounced moonlight without adding ambient fill. Generator and corridor lighting stay off until their puzzle states allow them.

## Node structure

```text
EntryRoomPuzzle                         entry_puzzle.gd — objective/signal wiring
├─ Room                                instance of your existing entry_room.tscn
│  ├─ ...architecture and props...
│  ├─ ...Storage_Rack
│  │  ├─ SearchableContainer            searchable_container.gd
│  │  └─ SearchInteractable             Area3D + interactable.gd
│  │     └─ InteractionShape            CollisionShape3D
│  └─ ...Unpowered_Access_Panel
│     └─ PanelInteractable              Area3D + interactable.gd
├─ Breach_Revision_CSG                  editable collapsed-edge geometry
├─ BreachMoonlight                     the initial room's only active light
├─ Generator                           generator.gd
│  ├─ ...editable CSG housing...
│  ├─ BodyInteractable                  Area3D + interactable.gd
│  ├─ LeftSlot_4                        fuse_slot.gd; required_item=fuse_square
│  │  ├─ Socket_Plate / Empty_Socket     editable CSG
│  │  ├─ Corners_Label                 Label3D: 4
│  │  ├─ ScrewPivot                    rotating, translating fuse visual
│  │  ├─ FocusCameraPose               Marker3D for the camera tween
│  │  └─ Interactable                  Area3D + interactable.gd
│  │     ├─ InteractionShape
│  │     └─ UseArea                     Area3D; player proximity sphere
│  ├─ RightSlot_3                       same structure; fuse_triangle
│  ├─ StartLever / Interactable
│  ├─ Yellow_Power_No_Fuel / Green_System_Ready
│  └─ EngineLoop / ReadyBeep            AudioStreamPlayer3D
├─ FuelTank_CSG
│  └─ FuelValveAndLock                  fuel_lock.gd; combination=532
│     ├─ ValveWheel
│     ├─ FallingPadlock                frozen RigidBody3D; released on unlock
│     └─ Interactable
├─ FuelCodePaper                       clue_paper.gd
│  ├─ PaperMesh                        uses your fuelcodepaper.jpeg
│  └─ Interactable
├─ ExitDoorController                  exit_door.gd; references existing DoorLeaf
├─ Heavy_Door_Power_Cable_CSG / Fuel_Pipe_CSG
├─ Generator_Powered_Lighting           off until engine starts
├─ Main_Bunker_Corridor_Placeholder      collidable continuation beyond the door
└─ Player                              bunker_player.gd; CharacterBody3D
   ├─ PlayerCollider
   ├─ Camera3D
   ├─ InventoryManager                 inventory_manager.gd; per-player Node
   ├─ CameraInteractor                 camera_interactor.gd
   ├─ ScrewInteraction                 screw_interaction.gd
   └─ GameHUD                          game_hud.gd; CanvasLayer
      ├─ MessageTimer
      └─ Canvas                        Control
         ├─ Location / Objective / Reticle / InteractionPrompt / Controls
         ├─ ModalBackdrop              ColorRect
         ├─ InventoryUI                PanelContainer + inventory_ui.gd
         │  └─ Layout                  VBoxContainer
         │     ├─ Heading / Hint
         │     ├─ ItemList             click selects an item
         │     ├─ ItemDescription
         │     ├─ UseButton            appears only after selection
         │     └─ CloseButton
         ├─ CombinationLockUI          LineEdit + Unlock/Cancel Buttons
         ├─ FuelCodePaperUI            TextureRect + Close Button
         ├─ ScrewingProgressUI         ProgressBar + instructions
         └─ FeedbackMessage
```

All UI controls and 3D placeholders are saved in the scene and can be edited in Godot. Inventory rows are populated from the player's current items at runtime.

## Modular scripts and assignments

| Script | Inspector assignments / responsibility |
| --- | --- |
| `scripts/inventory/item_definition.gd` | `BunkerItem` Resource: ID, display name, symbol, description, optional icon, color |
| `scripts/inventory/inventory_manager.gd` | Per-player collection, capacity and transactional item reservations; `changed` and `use_requested` signals |
| `scripts/interaction/interactable.gd` | Assign **Controller**, interaction text and optional **Use Area**. Add a CollisionShape3D. |
| `scripts/interaction/camera_interactor.gd` | Assign **Camera** and **Player Body**; set reach and collision mask. Runs the camera ray and resolves USE targets. |
| `scripts/interaction/searchable_container.gd` | Assign **Contents** item Resources and its **Interactable**. Loot cannot be collected twice. |
| `scripts/interaction/screw_interaction.gd` | Assign **Player** and **Camera**. Tune focus seconds and radians per mouse pixel. |
| `scripts/puzzle/fuse_slot.gd` | Assign **Required Item**, label, **Interactable**, **Screw Pivot**, **Focus Marker**; tune turns, local axis and insertion offset. |
| `scripts/puzzle/generator.gd` | Assign both slots, start target, indicator lights/materials, powered room lights and audio players. |
| `scripts/puzzle/fuel_lock.gd` | Assign generator, padlock Rigidbody, valve wheel and target. Combination defaults to **532**. |
| `scripts/puzzle/exit_door.gd` | Assign generator, door leaf, panel target/material/light; tune opening offset and seconds. `opened` is the final door-opening signal. |
| `scripts/puzzle/clue_paper.gd` | Assign the paper texture; F opens it in the HUD. |
| `scripts/ui/inventory_ui.gd` | Assign inventory, ItemList, description, USE and CLOSE controls. |
| `scripts/ui/game_hud.gd` | Assign popup roots, text/buttons, progress bar, prompt/objective/message controls. |
| `scripts/player/bunker_player.gd` | Assign camera, inventory, interactor, screw component and HUD. Coordinates input and movement locks. |

These assignments are already made in the delivered scene. No hard-coded node lookup is used by the gameplay components to find their meshes or controls.

## F-key ray interaction

The `interact` input action is mapped to physical **F** in Project Settings → Input Map. `bunker_player.gd` routes a press to `CameraInteractor.interact()` when no modal or screw interaction is active. The interactor casts from the camera along its forward direction with `PhysicsRayQueryParameters3D`.

Collision layers:

- **Layer 1:** solid world geometry, the player and padlock.
- **Layer 2:** interactable Area3D targets.
- **UseArea:** no collision layer; monitors player bodies on layer 1.

The ray includes both bodies and areas, excludes the player's own body, and accepts only the **first** hit. A solid wall or prop therefore blocks interaction with a target behind it. Place a target's collision shape just in front of, or slightly around, its visual mesh so the mesh does not hide its own interaction target.

See the complete working implementation in `scripts/interaction/camera_interactor.gd` and the input routing in `scripts/player/bunker_player.gd`.

## Inventory USE transaction

1. ItemList selection reveals USE and its description.
2. USE emits `InventoryManager.use_requested(item_id)`.
3. The player asks the interactor to resolve a compatible aimed target. It can also resolve the compatible target when the player overlaps its assigned UseArea.
4. If no compatible target accepts the item, the HUD displays exactly **“This item cannot be used here.”** The item remains in inventory and the inventory stays open.
5. A correct slot reserves the item and itself. The inventory closes and installation starts.
6. Completion consumes the reservation once. Cancelling releases it and resets the fuse visual. A wrong symbol or occupied slot never consumes an item.

Inventory data, slot compatibility, interaction targeting and UI are separate scripts. Star and Circle remain valid inventory items but neither matches an entry-room slot.

## Screwing mini-game

`ScrewInteraction` transitions through **IDLE → FOCUSING → ROTATING → RETURNING → IDLE**.

- Movement and normal mouselook are locked through focusing, turning and camera return.
- The camera tweens to the slot's Inspector-assigned `FocusCameraPose` and a closer FOV.
- `InputEventMouseMotion.screen_relative` feeds the signed delta `(x - y) × radians_per_pixel` into a clamped angle. **Right or up tightens; left or down loosens.** Reversing direction unwinds instead of awarding free progress.
- The pivot rotates around its **local** axis and translates by the configured insertion offset as progress increases.
- Completing the configured number of turns commits the fuse, then restores camera/FOV and movement. Esc cancels and returns the fuse. A reservation is also released if the active component exits the scene.

The player's `Camera3D` must not have a separate mouselook script that continues rotating it while this component owns it.

## Generator state machine

```text
MISSING_COMPONENTS
  F on panel → "No power."
  F on generator → "Missing components."
  Left slot accepts Square; right accepts Triangle.
       │ both correctly screwed in
       ▼
POWERED_NO_FUEL
  Yellow indicator on
  "Generator has power, but no fuel."
  Fuel valve opens the 3-digit lock UI.
       │ correct code 532; padlock drops; beep plays
       ▼
SYSTEM_READY
  Green indicator on
  "System ready."
  Engine remains off until F on the separate START lever.
       │ F on START
       ▼
RUNNING
  Looping diesel audio; room/corridor lights restored
  F on the exit panel → green display; door slides open slowly
       │ tween completes; ExitDoorController.opened signal
       ▼
  Clear collidable passage into the continuation corridor
```

`Generator.state_changed`, `fuel_unlocked` and `engine_started` are available for later systems. `ExitDoorController.opening_started` and **`opened`** are available for the next level, objectives and audio.

The audible diesel loop and ready beep are original synthesized placeholder audio. The `.res` audio resources retain their loop settings; `.wav` copies are also supplied for replacement or editing. No existing texture or audio asset was overwritten.

## Puzzle locations / quick verification

- Square: west storage rack.
- Triangle: north storage rack.
- Star decoy: east storage rack.
- Circle decoy: second timber crate.
- Paper clue: on the floor near the landing debris.
- Generator: east side of the central floor area.
- Fuel tank and locked valve: beside the south wall.

Use Area spheres and FocusCameraPose markers are visible in the editor. Select a slot to tune reach, framing and installation travel. Use the viewport's unshaded display while arranging dark geometry, then return to normal display to check lighting.

## Four-player integration boundary

This is a **functional local gameplay prototype**, with the existing four arrival markers preserved. It does not create a network lobby, transport, replicated inventory or authoritative multiplayer session.

For the later co-op pass, keep inventory per player and generator/door state shared. Route container claims, slot reservations, completion, combination submission and start/door requests through the server. Validate reach and item ownership there, and replicate the resulting state, indicators and door transform. Only the local player should own camera, input, HUD and the screwing camera tween. Current signals and component boundaries give those systems distinct integration points; calling local methods is not a network security boundary.

## Repeatable gameplay test

`tests/entry_room_flow_test.gd` exercises the camera ray, F-action routing, unique container loot, inventory selection/USE, wrong-use and decoy rejection, proximity use, cancellation, both mouse rotation directions, camera/control restoration, generator states, wrong/correct lock codes, indicators, looping audio and physical door clearance.

Run it with your Godot executable:

```text
godot --headless --path "<BreachBunker folder>" --script res://tests/entry_room_flow_test.gd
```

It exits with code 0 on success and writes `puzzle_validation.txt` under the project's `user://puzzle_tests` directory. Omit `--headless` to also generate the walkthrough screenshots. An optional `-- --artifacts "<output folder>"` selects a different report/screenshot folder.

## Godot references

- [Ray casting and collision exceptions](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html)
- [Mouse motion and resolution-independent screen_relative](https://docs.godotengine.org/en/4.7/classes/class_inputeventmousemotion.html)
- [Node editable instances](https://docs.godotengine.org/en/stable/classes/class_node.html)
