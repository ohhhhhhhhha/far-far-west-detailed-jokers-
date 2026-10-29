# Changes / 更新记录

## 0.3.0-beta.7 — Card UI and effect feedback fixes

- Reattach a valid current-world F7 root after native viewport removal.
- Skip full inventory/global-card polling while F7 and native menus are closed; retain bootstrap, UI-event and explicit refreshes.
- Compare effects without enforcing the vanilla equip-copy limit in description previews. Read live C_Joker_Lunge samples for existing/next counts and retain held totals. Missing samples do not become No bonus.
- Label F7’s vanilla equip limit as a reference; live Lunge effect limits follow the current game curve.
- Add reproductions for detached views, idle work and modified/capped Lunge values. The exact multiplayer stutter report still requires real-game comparison.

修复 F7 脱离视口后不显示，减少无菜单时的后台读取和扫描。无加成由效果变化决定；突刺使用当前游戏曲线，已持有效果保留。真实联机卡顿没有在离线测试中完整复现。


## 0.3.0-beta.6 — Nexus content packaging

- Remove the framework-signature payload from GameRoot. Obtain the complete game adaptation from Nexus 2, version 3.0.1.1183 (file 242).
- Keep all 14 card files byte-identical to beta.5; no card rules, controls or UI behavior change.
- Document the distinct framework/content destinations, Data backup and migration, activation, controls, troubleshooting, disable and rollback in both languages.
- Verify the archive through the shared Nexus contract, preserving all 24 framework files and existing component Data. Earlier release assets remain unchanged.

移除内容包中的框架签名，采用 Nexus 2 专用框架；14 个卡牌文件与 beta.5 一致。补齐完整双语安装与回滚指南，并通过共享安装契约检查框架文件和 Data 保留。旧版本附件不变。


## 0.3.0-beta.5 — 2026-10-29 candidate

- Guard queued input and native UI refresh against world/controller/character changes and replaced module instances.
- Retire old-world views without calling their native widgets; clean surviving same-world UI and preserve description restoration across possession gaps.
- Reset reactive card snapshots on context changes and select the local controller in host/guest scenarios.
- Keep F7 button text on one line, use native ellipsis, remove width-changing selection markers and adapt pagination to viewport/DPI.
- Include the shared ProcessLocalScriptFunction signature and its MIT attribution for fresh installations.
- Preserve beta.4 effect calculations and full F7 rules. Native AV causation remains unproven; multiplayer/pixel acceptance is pending.

修复旧世界回调和控件清理、短暂无角色及旧版重载边界；调整 F7 单行文字与自适应分页，并随包提供首次启动所需的共享签名。保持 beta.4 条件加成和完整规则。原生 AV 不能据离线测试宣称已解决。

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
