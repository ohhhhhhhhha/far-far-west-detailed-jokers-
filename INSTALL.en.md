# Installation, updates and removal

## First installation

1. Fully exit the game. Use Steam → Manage → Browse local files to find its directory.
2. Install a compatible official UE4SS distribution separately. This package does not replace loader DLLs or configuration.
3. Extract this package and merge the contents of GameRoot into the game directory. The scan override must be at FarFarWest/Binaries/Win64/ue4ss/UE4SS_Signatures/ProcessLocalScriptFunction.lua; the card component belongs under Mods/FFWJokerInfo beside that directory.
4. **Install both the framework and this game's signature before the first launch.** Open F7 in the lobby. After travel, press F7 again to rebuild the panel.

No terminal or batch script is needed. Preserve existing UE4SS-settings.ini, mods.txt, player Data and saves. The component includes enabled.txt; follow the activation rules of the official framework build being used.

## Updating

Exit the game, back up FFWJokerInfo and the existing signature, then merge the new GameRoot. Fully restart; returning to the title screen does not reload scripts. An old Scripts/Spawner.lua may be removed because spawning moved to the separate trainer.

## Displays and paths

Panel geometry uses the game viewport and DPI. Common resolutions/scales have model coverage; actual font pixels still need local acceptance.

Package checks include real Node extraction into Chinese/space-containing paths and a Lua virtual filesystem. UE4SS 1181's Lua loader uses narrow fopen, so these checks do not prove non-ASCII loading under every Windows system code page. If logs report script-path loading errors, use Steam Settings → Storage to add an ASCII-only library path and Steam's Move installation feature to test there. Do not change the system locale, registry or global Lua locale.

## Removal and rollback

Exit the game and remove or move Mods/FFWJokerInfo. Keep the shared signature if another mod still needs it. Roll back only this component and its backed-up signature, preserving other mods, Data and official loader settings.

See [UE4SS compatibility scope](UE4SS-COMPATIBILITY.en.md).
