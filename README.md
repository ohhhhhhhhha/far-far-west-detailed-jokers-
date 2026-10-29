# Far Far West — Detailed Joker Effects

[简体中文](README.zh-CN.md) · [Download](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/releases/tag/v0.3.0-beta.7) · [Report an issue](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/issues)

**FFWJokerInfo · 0.3.0-beta.7 · UE4SS · Windows x64**

Adds calculated effects to the original Joker pickup descriptions and Tab hover details. F7 provides full rules and live readings. Chinese and English follow the game language.

## Fixed in beta.7

- F7 reattaches its still-valid current-world widget if the game removes it from the viewport.
- Closed-overlay gameplay skips periodic full inventory reads and global card scans. Native UI events, open menus and explicit refreshes still update descriptions.
- No bonus follows the effect comparison, rather than the vanilla equip-copy limit. Lunge reads the game’s current curve for the owned and next-copy values; missing samples are not treated as zero benefit. Owned stacks retain their total, including at a real cap.

The offline reproduction covers detached F7 widgets, idle work and Lunge counts beyond four. The reported friend’s real multiplayer stuttering still needs an in-game comparison; these tests do not measure native FPS.

## Lifecycle and display fixes

F7 closes when its world, local controller or character context changes. Press F7 again after loading to create a fresh panel. Queued actions from a retired world or module instance are discarded. A temporary unpossessed state preserves same-world description restoration data. The list uses stable one-line captions and adapts its row count to the viewport and DPI.

## Card descriptions

- Pickup previews show the relevant change as current → after pickup. Owned cards show their current total, including effects at their cap.
- Conditional bonuses are shown with their trigger. Bouncing Ball previews ×1 → ×1.15 while grounded, then ×1.15 → ×1.3 for another copy; these are airborne weapon-damage multipliers.
- Resource-dependent cards show a labelled trigger value or growth rate when an empty resource hides the benefit.
- Red **No bonus** appears only in pickup previews when no effective change is established. Weapons outside the card's allowed list still show No bonus; basic punches do not bypass weapon-specific restrictions.
- Prickly Pear shows its fixed bonus, retaliation formula and health-damage trigger instead of asking for the next damage event.
- Native descriptions omit copy counts and stacking/cap footers. F7 retains the full counts, stacking rules, caps and event-dependent readings.

Descriptions are left-aligned, wrap in a bounded area and can be scrolled. For example, two Lightweight cards alone give gravity 1.15, an 8% reduction from the 1.25 base. Card percentages should not simply be added.

## Install or update

This is a content-only package with no framework signature. Use the [Nexus 2 game-specific UE4SS player package](https://www.nexusmods.com/farfarwest/mods/2), checked as Main file UE4SS-FarFarWest 3.0.1.1183, file ID 242.

1. Fully exit. Before migrating an old framework, back up its complete installation and verify every mod’s Data/settings are preserved outside the active Mods directory.
2. Steam → Manage → Browse local files opens the game root containing FarFarWest.exe. Install the Nexus framework inside **FarFarWest/Binaries/Win64**, beside FarFarWest-Win64-Shipping.exe.
3. Extract the card runtime ZIP and merge the **contents inside GameRoot** into the game root from step 2. Do not copy GameRoot itself or put the content archive’s whole structure into the inner Win64 directory.
4. Check ue4ss/Mods/FFWJokerInfo/enabled.txt and Scripts/main.lua, fully restart, enter the lobby and press F7.

This package installs only 14 card files and preserves Nexus’s DLLs, configuration, shared helpers and complete signature set, as well as existing Data. The older beta.5 archive still has a compatibility signature: copy only its Mods/FFWJokerInfo subtree if using that old file. Previously published assets are unchanged.

No terminal or batch script is needed. The [full guide](INSTALL.en.md) covers the exact tree, Data backup, migration, activation, controls, updates, diagnostics, disable and rollback. See also [framework dependency details](UE4SS-COMPATIBILITY.en.md).

## Controls

F7 opens or closes full details. Use the mouse to select, page and close; the wheel scrolls details. F5/F6 selects the previous/next entry, and Shift + F5/F6 changes pages. Closing restores camera control.

## Source and verification

This repository and its downloads contain only Detailed Joker Effects and its dependencies. It displays information without changing inventory, progression or combat. Spawning, trainer features and combat statistics are separate components.

Lua source and regression tests are under FFWTools. The catalog audit covers 183 card/upgrade entries, 28 retained curves and 27,600 description scenarios. The beta.5/6 baseline had user-confirmed single-player F7, mouse and return-to-title checks; beta.7's native changes still need the in-game check described in INSTALL. Host/guest/DPI models have offline coverage; actual LAN/IP-direct-connect multiplayer acceptance is still tracked separately. Native-crash investigation remains separate. See [development notes](DEVELOPMENT.md) and [changes](CHANGELOG.md).

## Support and license

In [GitHub Issues](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/issues), include the mod, game and UE4SS versions, exact weapon/card names, reproduction steps and relevant error text. Omit saves, account identifiers and personal paths.

Original code and documentation use the [MIT license](LICENSE). Game-derived text and data retain their original rights; see [third-party notices](THIRD-PARTY-NOTICES.md).
