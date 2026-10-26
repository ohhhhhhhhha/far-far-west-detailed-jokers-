# Far Far West — Detailed Joker Effects

[简体中文](README.zh-CN.md) · [Download](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/releases/tag/v0.3.0-beta.3) · [Report an issue](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/issues)

**FFWJokerInfo · 0.3.0-beta.3 · UE4SS · Windows x64**

- Append current effects and pickup previews to original Joker descriptions and Tab hover details.
- Show only relevant changed metrics; omit copy counts and stacking/cap labels from native descriptions.
- Show a known lack of effective bonus in red. Missing inputs remain unread instead of being treated as zero.
- Keep full counts, stacking rules, caps and conditions in the F7 details panel.
- Chinese/English follows the game language; mouse selection, paging, scrolling and closing work without Esc.

For example, two LIGHTWEIGHT cards alone yield gravity 1.15, an 8% reduction from the 1.25 base in this baseline. Percentages should not simply be added. This component only displays information; it does not spawn cards or change progression.

## Install

Tested with Far Far West 0.3.0.7 and UE4SS build 1181. Install a compatible [UE4SS build](https://github.com/UE4SS-RE/RE-UE4SS) separately.

1. Close the game and download [FFWJokerInfo-0.3.0-beta.3.zip](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/releases/download/v0.3.0-beta.3/FFWJokerInfo-0.3.0-beta.3.zip).
2. Extract the ZIP outside the game folder.
3. Copy the contents of GameRoot into the game folder opened through Steam → Manage → Browse local files.
4. Press F7 in the game to open full details.

No terminal or installation script is required. Read [installation, update and removal instructions](INSTALL.en.md) before updating an older version.

## Controls

F7 opens/closes details. Use the mouse to select, page and close; the wheel scrolls details. F5/F6 selects the previous/next entry; Shift + F5/F6 changes pages. Closing restores camera controls.

## Source and verification

This repository contains only Detailed Joker Effects and its required dependencies. The other tool and combat-statistics/synchronization mods are not included. Shared calculation and language files are copied into this repository, so it can be used independently.

Lua source is under FFWTools/src/FFWJokerInfo/Scripts. See [development notes](DEVELOPMENT.md) and [changes](CHANGELOG.md). The v0.3.0-beta.3 split preserves the accepted runtime payload. Offline checks do not mean every possible combination was tested in-game.

## Support and license

Maintained by FFWTools contributors. In [GitHub Issues](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/issues), provide the tool version, game/UE4SS versions, reproduction steps and relevant error text. Omit saves, account identifiers and personal paths.

Original code and documentation use the [MIT license](LICENSE). Game-derived text and data retain their original rights; see [third-party notices](THIRD-PARTY-NOTICES.md).
