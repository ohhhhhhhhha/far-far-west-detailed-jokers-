# 安装、升级与卸载 — 更详细的奇术卡资料

需要 Windows x64，并已为 Far Far West 安装可正常工作的 UE4SS。验证基线：游戏 0.3.0.7 / UE4SS build 1181。包内不附 UE4SS。

## 安装

1. 退出游戏，在 Steam 中选择“管理 → 浏览本地文件”。
2. 将运行 ZIP 解压到该目录之外。
3. 把 GameRoot 内的内容复制到游戏目录并合并文件夹。
4. 在游戏中按 F7 打开完整详情。

Lua 入口应位于 FarFarWest/Binaries/Win64/ue4ss/Mods/FFWJokerInfo/Scripts/main.lua；附带的 FarFarWest/Binaries/Win64/ue4ss/Mods/FFWJokerInfo/enabled.txt 用于启用组件。无需命令、安装脚本或覆盖 mods.txt。

若使用自定义 UE4SS 工作目录，请将 FFWJokerInfo 文件夹复制到实际的 Mods 目录。

## 升级

关闭游戏，将旧 FFWJokerInfo 文件夹备份到 Mods 之外。仅删除其 Scripts 子目录，再复制新版 GameRoot 内容；保留 Data 和自定义文件。这可清除旧版遗留脚本，不覆盖其他 Mod 或全局设置。

## 禁用与卸载

将 enabled.txt 移出 FFWJokerInfo 文件夹。如果 mods.txt 已有 FFWJokerInfo 条目，还需将该条目改为 0：enabled.txt 会绕过 mods.txt。禁用后删除组件的 Scripts 子目录即可移除。

## 参考

- [UE4SS 安装规范](https://docs.ue4ss.com/dev/installation-guide.html)
- [Lua Mod 入口规范](https://docs.ue4ss.com/guides/creating-a-lua-mod.html)
- [启用标记与加载顺序](https://docs.ue4ss.com/guides/installing-a-c%2B%2B-mod.html)
