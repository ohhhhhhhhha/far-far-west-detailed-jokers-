# Changes / 更新记录

## 0.3.0-beta.4 — 2026-10-27

- Fix conditional effects being reported as No bonus while their trigger is inactive, including airborne damage.
- Keep No bonus limited to pickup previews; retain current totals for owned stacks at a cap and preserve weapon applicability restrictions.
- Clarify resource-dependent effects and mixed missing-input states without inventing active bonuses.
- Give Prickly Pear a compact fixed-bonus/formula display; keep full event readings in F7.
- Left-align native descriptions, clear inherited offsets, retain bounded scrolling and restore original layout on unload/reload.
- Add full-catalog, condition, applicability and native-layout regressions. F7 detail rules and game state are unchanged.

修复条件加成与资源状态的误报，保留不适用武器的“无加成”；精简尖刺反伤说明并调整卡面排版。F7 完整规则保持不变。

## 0.3.0-beta.3

- Publish FFWJokerInfo in its own repository, with independent source and runtime downloads.
- Copy-install packaging, bilingual README and installation/removal instructions; no player command-line steps.
- Include enabled.txt and document its precedence over mods.txt.
- Runtime payload matches the accepted 0.3.0-beta.2 build.

独立仓库、独立源码与运行包；完善双语说明，采用复制安装；运行内容保持已确认版本不变。

## 0.3.0-beta.2

- Accepted mouse interaction without Esc and camera restoration for the F7 information panel.
