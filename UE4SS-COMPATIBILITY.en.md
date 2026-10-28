# Framework dependency — Nexus game-specific package

FFWJokerInfo 0.3.0-beta.6 is a content mod. It bundles no UE4SS loader, configuration, shared helpers or scan signatures. Card Lua matches beta.5; this revision changes packaging and guidance.

## Player download and destinations

Use [Nexus 2 — UE4SS for FarFarWest](https://www.nexusmods.com/farfarwest/mods/2), by anro / AnroG772. The checked baseline is game 0.3.0.7 and the Frostburn / UE 5.8 player Main file UE4SS-FarFarWest 3.0.1.1183 (file ID 242). Players do not need zDEV.

Steam’s Browse local files opens the game root containing FarFarWest.exe. The framework ZIP directly contains dwmapi.dll, ue4ss and README.md. Place those framework contents in **FarFarWest/Binaries/Win64** inside the game root, beside FarFarWest-Win64-Shipping.exe. In contrast, the card archive’s GameRoot contents go into the game root opened by Steam. Do not interchange these destinations.

See [INSTALL.en.md](INSTALL.en.md) for first installation, full backup/migration, Data preservation, activation, controls, diagnostics, disable and rollback.

## Framework ownership

Keep Nexus’s DLLs, UE4SS-settings.ini, mods.txt/mods.json, Mods/shared and all three signatures: FName_Constructor.lua, GNatives.lua and ProcessLocalScriptFunction.lua. They belong to the matched game adaptation; this component does not write those locations.

beta.5 bundled an earlier compatibility-signature implementation. Its published asset keeps its original hash. Install only its Mods/FFWJokerInfo subtree if using that older ZIP. beta.6 no longer supplies that signature and needs no additional Nexus signature overwrite.

Before migration, back up the complete framework and every mod’s Data/settings outside Mods. Do not copy an old global configuration, signature set or shared library over the new Nexus framework. Restore compatible Data according to each component’s version instructions and leave real saves in place.

## Attribution and evidence

[UE4SS upstream source](https://github.com/UE4SS-RE/RE-UE4SS) remains the source reference; the player setup uses the Nexus adaptation above. Startup compatibility depends on versions, signatures and settings together.

The actual checked Nexus ZIP has SHA-256 87c1d83576e43324c2310f8a7fd3961d71dcab07d75f4b1fbf3bb0c2c226b375 and 24 files. This digest identifies the inspected baseline, not future author updates.

The content archive uses the shared installation contract to check preservation of the framework and synthetic Data in an isolated directory. That file-copy check does not replace native runtime, real LAN/IP-direct-connect or all Windows path-codepage checks. No system-locale, driver or graphics-setting change is needed.
