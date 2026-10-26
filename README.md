# Far Far West — Detailed Joker Effects

[简体中文](README.zh-CN.md) · [Download](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/releases/tag/v0.3.0-beta.4) · [Report an issue](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/issues)

**FFWJokerInfo · 0.3.0-beta.4 · UE4SS · Windows x64**

Adds calculated effects to the original Joker pickup descriptions and Tab hover details. F7 provides full rules and live readings. Chinese and English follow the game language.

## Card descriptions

- Pickup previews show the relevant change as current → after pickup. Owned cards show their current total, including effects at their cap.
- Conditional bonuses are shown with their trigger. Bouncing Ball previews ×1 → ×1.15 while grounded, then ×1.15 → ×1.3 for another copy; these are airborne weapon-damage multipliers.
- Resource-dependent cards show a labelled trigger value or growth rate when an empty resource hides the benefit.
- Red **No bonus** appears only in pickup previews when no effective change is established. Weapons outside the card's allowed list still show No bonus; basic punches do not bypass weapon-specific restrictions.
- Prickly Pear shows its fixed bonus, retaliation formula and health-damage trigger instead of asking for the next damage event.
- Native descriptions omit copy counts and stacking/cap footers. F7 retains the full counts, stacking rules, caps and event-dependent readings.

Descriptions are left-aligned, wrap in a bounded area and can be scrolled. For example, two Lightweight cards alone give gravity 1.15, an 8% reduction from the 1.25 base. Card percentages should not simply be added.

## Install or update

Baseline: Far Far West 0.3.0.7 and UE4SS build 1181. Install a compatible [UE4SS build](https://github.com/UE4SS-RE/RE-UE4SS) separately.

1. Fully exit the game and download [FFWJokerInfo-0.3.0-beta.4.zip](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/releases/download/v0.3.0-beta.4/FFWJokerInfo-0.3.0-beta.4.zip).
2. Extract the ZIP outside the game folder.
3. Copy the contents of GameRoot into the game folder opened through Steam → Manage → Browse local files, replacing this mod's old files.
4. Restart the game. Returning to the title screen does not reload Lua modules.

No terminal or installer script is required. See [installation, update and removal instructions](INSTALL.en.md).

## Controls

F7 opens or closes full details. Use the mouse to select, page and close; the wheel scrolls details. F5/F6 selects the previous/next entry, and Shift + F5/F6 changes pages. Closing restores camera control.

## Source and verification

This repository and its downloads contain only Detailed Joker Effects and its dependencies. It displays information without changing inventory, progression or combat. Spawning, trainer features and combat statistics are separate components.

Lua source and regression tests are under FFWTools. The catalog audit covers 183 card/upgrade entries, 28 retained curves and 27,600 description scenarios. The latest logic and layout changes have offline regression coverage; this is not a claim that every combination or the latest layout has been verified in-game. See [development notes](DEVELOPMENT.md) and [changes](CHANGELOG.md).

## Support and license

In [GitHub Issues](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/issues), include the mod, game and UE4SS versions, exact weapon/card names, reproduction steps and relevant error text. Omit saves, account identifiers and personal paths.

Original code and documentation use the [MIT license](LICENSE). Game-derived text and data retain their original rights; see [third-party notices](THIRD-PARTY-NOTICES.md).
