# RECONSTRUCTION_MANIFEST

## Status
CONTROLLED_RECONSTRUCTION=YES
ORIGINAL_LOST_F3_F5_SOURCE=NO

This branch is a controlled reconstruction authorized by the user on 2026-09-07/08. It is **not** the original source that produced the previously tested F5 APK.

## Functional baseline
The intended behavior is reconstructed from the preserved F2 candidate (`rpg-fantasia-oscura-vslice-f2-candidate.zip`, Drive ID `13Z5s7yXFtOLHDe7BX_Ufhs7jXidKOJmn`) plus the approved F3-F5 and M4-M6 specifications.

## Physical scaffold
Because the current ChatGPT local runtime cannot extract the F2 ZIP (container/python return ClientError), this branch starts from the repository's P1.3 main commit `b788d8e51378fe57035a4a90aa62191b75848068` solely as a code/assets scaffold. The reconstructed gameplay is isolated under `game/rebuild/` and does not claim lineage equivalence with the lost source.

## Frozen contract
- Godot 4.7.2 Standard
- 640x360 logical viewport
- landscape
- canvas_items + expand
- GL Compatibility
- Android package `cl.javix142.fantasiaoscura`
- minSdk 28
- targetSdk 36
- arm64-v8a only

## Reconstructed scope
- F2 combat loop: melee, dodge, HP, death/respawn, enemies, drops, potion.
- F3: Liria attack, destroyed-state map, wave and story progression.
- F4: Camino Prohibido, Ceniza/shop, Cyrion ruin exterior/interior, 2-phase boss, slice ending.
- F5: pause/settings hooks, save/load, regression and Android build.
- M4: explicit animation states and combat VFX.
- M5: differentiated zone composition and shared visual/collision data.
- M6: safe-area UI, touch controls, layout polish, regression/build gate.

## Rule
Only CI evidence may mark automated gates PASS. Final physical gate remains the user's responsibility.
