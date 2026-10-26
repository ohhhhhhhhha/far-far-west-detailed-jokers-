# Install, update and remove — Detailed Joker Effects

Requires Windows x64 and a working UE4SS installation for Far Far West. Tested baseline: game 0.3.0.7 / UE4SS build 1181. UE4SS is not bundled.

## Install

1. Exit the game. In Steam, choose Manage → Browse local files.
2. Extract the runtime ZIP outside that directory.
3. Copy the contents of GameRoot into the game directory, merging folders.
4. Press F7 in the game to open full details.

The Lua entry must be at FarFarWest/Binaries/Win64/ue4ss/Mods/FFWJokerInfo/Scripts/main.lua. The included FarFarWest/Binaries/Win64/ue4ss/Mods/FFWJokerInfo/enabled.txt enables this component. No command, installation script or replacement mods.txt is needed.

For a custom UE4SS working directory, copy the FFWJokerInfo mod folder to its actual Mods directory.

## Update

Close the game. Back up the old FFWJokerInfo folder outside Mods. Remove only its Scripts subfolder, then copy the new GameRoot contents. Preserve Data and other custom files. This clears removed scripts from earlier versions without replacing other mods or global settings.

## Disable or remove

Move enabled.txt out of the FFWJokerInfo folder. If mods.txt already contains a FFWJokerInfo entry, change that entry to 0 as well: enabled.txt bypasses mods.txt. To remove the component, remove its Scripts subfolder after disabling it.

## References

- [UE4SS installation](https://docs.ue4ss.com/dev/installation-guide.html)
- [Lua mod entry layout](https://docs.ue4ss.com/guides/creating-a-lua-mod.html)
- [Activation marker and load ordering](https://docs.ue4ss.com/guides/installing-a-c%2B%2B-mod.html)
