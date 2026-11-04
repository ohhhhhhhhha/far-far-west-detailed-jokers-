# FFWJokerInfo 0.3.0-beta.14

Beta prerelease; changes since public 0.3.0-beta.10:

- Reduce controller scrolling work: neutral input skips full-card discovery; local-menu checks and 10Hz idle / 30Hz moving gates precede full context reads; unchanged boundary offsets are not rewritten.
- Keep unread spell slots pending and recover on the next successful read. Invalidate stale Hit Me observations when a new eligible trigger cannot be read.
- Select and page from the displayed F7 snapshot. Keep card identity through background insertions and incomplete reads; queued clicks keep their original target.
- Skip unchanged F7 control writes; refresh after changed data, language, viewport, reopen, detach or reload. Label mixed known/unknown weapon effects correctly.
- Retry interrupted layout writes, including when the viewport returns to its previous size; preserve the last completed layout for navigation.

Offline regressions measure fewer native-call attempts, not game FPS. Physical controller behavior, native Slate rendering and multiplayer FPS still require in-game acceptance.

Install UE4SS for FarFarWest from [Nexus mod 2](https://www.nexusmods.com/farfarwest/mods/2), version 3.0.1.1183, Main file 242. Then fully exit the game and merge the contents inside the runtime ZIP's GameRoot into the game root containing FarFarWest.exe. This package includes only the 15 card-component files; no framework files or signatures are bundled. Preserve existing Data/settings. The source ZIP is for development.

---

相对公开 beta.10：减少右摇杆无输入扫描及重复上下文查询；修复法术槽读取失败和“打我呀”旧缓存；F7选卡/翻页复用已显示快照，保持选择和排队点击目标；跳过无变化控件写入；改善已知/未知武器效果标注；布局写入中断后完整重试，恢复原窗口尺寸也能恢复布局。

离线回归验证调用次数和恢复逻辑，真实手柄、原生Slate与联机FPS仍待实机验收。先安装 Nexus 2 专用框架3.0.1.1183（Main文件242），退出游戏后将运行包GameRoot里面的内容合并至含FarFarWest.exe的游戏根目录。仅含15个卡牌文件，不附带框架；保留已有Data/配置。SOURCE源码包用于开发。
