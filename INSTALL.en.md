# Detailed Joker Effects — installation, migration and troubleshooting

Component: FFWJokerInfo 0.3.0-beta.7. Updated 2026-10-29. This hotfix restores detached F7 views, reduces idle polling and uses live Lunge curve samples. Previously published assets remain unchanged.

## 1. Choose the two correct downloads

- Player framework: [Nexus 2 — UE4SS for FarFarWest](https://www.nexusmods.com/farfarwest/mods/2), by anro / AnroG772. Select the Frostburn / UE 5.8 player package. The author describes the player archive as **UE4SS-FarFarWest-v3.0.1-1183-frostburn.zip**. The actual checked Main file is **UE4SS-FarFarWest**, version **3.0.1.1183**, file ID **242**; Nexus may add identifiers to the downloaded filename. Players do not need the zDEV developer package.
- Card component: the Main runtime file on [Nexus 115](https://www.nexusmods.com/farfarwest/mods/115), or [FFWJokerInfo-0.3.0-beta.7.zip on GitHub](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/releases/download/v0.3.0-beta.7/FFWJokerInfo-0.3.0-beta.7.zip). The SOURCE ZIP is not an installation package.

Use the Nexus 2 game-specific package. It includes the signatures and configuration required by this game. UE4SS on GitHub remains the upstream source reference.

## 2. Find the correct directory

In the Steam library, right-click Far Far West → Manage → Browse local files. This opens the game root containing **FarFarWest.exe**. From there, continue into **FarFarWest/Binaries/Win64**. The framework belongs beside **FarFarWest-Win64-Shipping.exe**.

The final structure should look like this. Keep framework-owned files supplied by Nexus intact.

~~~text
<game directory opened by Steam>/
├─ FarFarWest.exe                              existing game file
└─ FarFarWest/
   └─ Binaries/
      └─ Win64/
         ├─ FarFarWest-Win64-Shipping.exe       existing game file
         ├─ dwmapi.dll                         from the Nexus framework
         └─ ue4ss/
            ├─ UE4SS.dll                       from the Nexus framework
            ├─ UE4SS-settings.ini              preserve Nexus configuration
            ├─ UE4SS_Signatures/               preserve the whole Nexus set
            ├─ UE4SS.log                       created after launch
            └─ Mods/
               ├─ mods.txt                    preserve existing configuration
               ├─ shared/                     preserve framework helpers
               └─ FFWJokerInfo/
                  ├─ enabled.txt              an empty file is normal
                  └─ Scripts/
                     ├─ main.lua
                     ├─ Scope.lua
                     ├─ Panel.lua
                     └─ the remaining bundled Lua files
~~~

Avoid Win64/Win64, ue4ss/ue4ss, or FFWJokerInfo/FFWJokerInfo/Scripts nesting. The outer game directory and inner FarFarWest directory legitimately share a name.

## 3. Migrating an older framework: back up first

If a working Nexus Frostburn framework is already installed, skip to section 5 and update only the card component.

1. Fully exit the game. Returning to its title screen is insufficient.
2. In File Explorer, copy the complete existing ue4ss directory and the dwmapi.dll belonging to that framework to a backup directory outside the game directory. Do not put backups inside ue4ss/Mods, where old mods may be discovered and loaded.
3. Verify that every mod's **`Mods/<ModName>/Data/`** directory is present in the backup. Retain its settings and the original mods.txt too. Mod Data may contain statistics/configuration; it is not the game's save folder. Leave real saves untouched.
4. After confirming the backup exists, move the old ue4ss directory and positively identified old-framework dwmapi.dll out of the active Win64 directory into a separate dated quarantine folder. Do not overwrite the backup or remove unidentified proxy DLLs. Never delete the whole ue4ss installation without first preserving Data.
5. Install the complete Nexus player framework as described below. Do not copy the old DLL, UE4SS-settings.ini, shared helper library or signature set over the new framework; that can reintroduce incompatible engine settings or scans.
6. Install compatible versions of the mods you need, then restore each mod's Data according to that component's upgrade instructions. Do not restore the whole old Mods directory over the new framework merely to recover Data. Keep anything not yet restored in the backup.

## 4. Install the Nexus game-specific framework

1. Extract the Nexus 2 player ZIP outside the game directory.
2. Locate dwmapi.dll and the ue4ss folder in the extracted contents, then place them in the Win64 directory from section 2. Do not copy an extra archive-wrapper folder into Win64.
3. Keep the package's DLL, UE4SS-settings.ini, Mods/shared and UE4SS_Signatures together. Its FName, GNatives and ProcessLocalScriptFunction files are part of that adaptation; do not remove or overwrite them because of an older card guide.
4. Launch only after the framework and its own configuration/signatures are in place. You may first check the framework alone at the title screen/lobby, then fully exit before adding the card mod.

For startup failures, inspect the final error in ue4ss/UE4SS.log. After a game update, check the supported version on the Nexus 2 author’s page.

## 5. Install the card component

The beta.7 GameRoot contains only the 14 FFWJokerInfo files. It contains no framework DLLs, settings, shared helpers or signatures. Install the Nexus dependency first.

1. Fully exit and extract FFWJokerInfo-0.3.0-beta.7.zip outside the game directory.
2. Open the archive’s **GameRoot** folder. Copy the **FarFarWest** folder inside it into the game root opened by Steam’s Browse local files, merging the matching directory. This destination contains **FarFarWest.exe**.
3. Do not copy the GameRoot folder itself or put its whole contents into the inner Win64 directory. The framework and content ZIPs have different destinations.
4. The resulting entry point must be:

   FarFarWest/Binaries/Win64/ue4ss/Mods/FFWJokerInfo/Scripts/main.lua

5. Replace only this component’s code and enabled.txt. Back up before updating; preserve existing Data/settings and other mods.
6. Alternatively, copy only GameRoot/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWJokerInfo into the game’s ue4ss/Mods directory. This gives the same result.

Keep Nexus’s UE4SS_Signatures, UE4SS-settings.ini, mods.txt/mods.json, Mods/shared and DLLs intact. This card archive no longer supplies a framework signature.

**Older archive:** the published beta.5 ZIP includes an earlier compatibility signature. When using that archive, copy only its Mods/FFWJokerInfo directory; do not merge all of its GameRoot. The beta.5 asset has not been replaced.

## 6. Enable and check the mod

- Confirm Mods/FFWJokerInfo/enabled.txt exists. An empty marker is normal. Scripts/main.lua and the other Lua files must be in the same complete installation.
- The runtime ZIP includes enabled.txt, so normally no mods.txt edit is needed. If following your framework's mods.txt activation method, change only this component's entry, not the whole file. The entry is FFWJokerInfo : 1.
- Show file extensions in File Explorer and rule out enabled.txt.txt or main.lua.txt.
- Fully launch the game and enter the lobby. Focus the game window and press F7; laptops using media-key mode may require Fn+F7.
- Select a card, page, scroll details, close the panel and check that camera control returns. In a mission, inspect a pickup and a Tab card tooltip.

The beta.5/6 baseline had confirmed single-player F7, mouse and return-to-title checks. Repeat these checks for beta.7, including opening F7 after a native menu closes. Real LAN/IP-direct-connect performance still needs an in-game comparison.

## 7. Controls

| Input | Result |
| --- | --- |
| F7 | Open/close full card details |
| Mouse click | Select, page and close |
| Wheel over details | Scroll long text |
| F5 / F6 | Previous/next entry |
| Shift + F5 / F6 | Previous/next page; capacity follows viewport/DPI |
| F7 after travel | Build a panel for the current world |

Original pickup and Tab-hover descriptions are enhanced automatically. F7 need not stay open. Effects respect the weapon applicability list; an incompatible pickup preview displays red No bonus. F2 resource editing belongs to the separate trainer, and F8 belongs to statistics.

## 8. Update only this component

1. Fully exit and back up Mods/FFWJokerInfo outside Mods.
2. Preserve any user settings or Data in it, and all other mods' Data.
3. Replace this component's code/marker from the new card ZIP. Do not reinstall or overwrite the working Nexus framework as part of a card update.
4. Very old mixed releases may contain FFWJokerInfo/Scripts/Spawner.lua, whose role moved to the independent trainer. After backup, move that obsolete file out as directed by the relevant version notes.
5. Fully restart and repeat the short check in section 6. Do not leave two enabled copies of the card mod under Mods.

beta.7 keeps the content-only layout introduced in beta.6. Previously published ZIPs retain their hashes. Do not copy a signature back from an older content package.

## 9. Troubleshooting

| Symptom | Check in this order |
| --- | --- |
| Startup crash or waiting for object construction | Check the Nexus 2 Frostburn player package, the Win64 directory containing Shipping.exe, and that the DLLs, settings and signatures come from the same framework bundle. Then inspect the final ue4ss/UE4SS.log error and confirm the game/framework versions. |
| No ue4ss/UE4SS.log | Check dwmapi.dll beside Shipping.exe and accidental extra directory nesting. First determine whether the loader started. |
| Loader starts but no FFWJokerInfo loaded message | Check folder structure, complete Lua files, enabled.txt name and duplicate copies. A second marker can keep a copy active despite a mods.txt edit. |
| Loaded message but F7 is absent | Fully restart, enter the lobby/mission and focus the game. Title/loading stages do not show it. Then inspect the corresponding FFWJokerInfo error in the log. |
| List text looks incomplete | Check version, viewport and DPI. Intentional single-line ellipsis keeps rows bounded; full details are in the title/detail area. Report abnormal wrapping or button overflow with resolution, scaling and the entry. |
| Panel closes during travel | Expected. Reopen F7 once the character is ready; report a failure to reopen with the associated error. |
| F2 opens but editing fails | Record the exact F2 message, then use the separate trainer’s guide to check the current game location, write conditions and application result. |
| Non-ASCII path loading errors | Read the path error; if needed, test an ASCII-only Steam library through Steam Storage/Move installation. Do not change system locale, registry or global Lua locale. Prior Node extraction/Lua VFS results do not verify every Windows code page. |

For a report, supply component/game/framework versions, exact card/weapon names, single-player or LAN/IP-direct-connect mode, steps and relevant error lines. Redact account identifiers, IPs and personal paths. Do not upload real saves, whole Data folders or unprocessed dumps.

## 10. Disable, roll back and keep data

- Simplest disable: exit the game and move the whole FFWJokerInfo folder outside Mods. Renaming it inside Mods may not disable it because its marker can still be discovered.
- If retaining the folder, move enabled.txt out and set an existing FFWJokerInfo entry in mods.txt to 0. The marker can override the list, so changing just one may not disable it.
- Card rollback: exit and move the current complete FFWJokerInfo folder outside Mods first. Restore the backed-up version at its original location without mixing old and new scripts. Restore compatible settings/Data according to that version’s instructions, retain anything not restored in the backup, then fully restart.
- Framework rollback: back up every mod’s current Data/settings, move the current framework out of active Win64, then restore the complete matching pre-migration backup. Restore compatible Data according to each component’s instructions and retain anything not restored. Leave actual saves in place.
- Disabling or rolling back this card component does not require deleting Nexus's shared signatures, which other mods may still use.

See [framework dependency and signature policy](UE4SS-COMPATIBILITY.en.md).
