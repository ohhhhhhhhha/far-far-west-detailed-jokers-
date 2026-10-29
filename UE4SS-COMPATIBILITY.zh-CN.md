# 框架依赖 — Nexus 游戏专用包

FFWJokerInfo 0.3.0-beta.7 是内容 Mod，不包含 UE4SS 加载器、配置、共享辅助库或扫描签名。此版修复卡牌界面恢复、闲置轮询和突刺曲线读取。

## 玩家下载与目录

使用 [Nexus 2 — UE4SS for FarFarWest](https://www.nexusmods.com/farfarwest/mods/2)，作者 anro / AnroG772。核对基线为游戏 0.3.0.7、Frostburn / UE 5.8 玩家主文件 UE4SS-FarFarWest 3.0.1.1183（文件 ID 242）。普通玩家无需 zDEV 包。

Steam“浏览本地文件”打开包含 FarFarWest.exe 的游戏根目录。框架归档顶层直接是 dwmapi.dll、ue4ss 和 README.md；将框架内容放到根目录内的 **FarFarWest/Binaries/Win64**，旁边应有 FarFarWest-Win64-Shipping.exe。卡牌内容包的 GameRoot 内部内容则复制到 Steam 打开的游戏根目录，不能把两个目标混用。

完整步骤见 [INSTALL.zh-CN.md](INSTALL.zh-CN.md)，含首次安装、旧框架备份迁移、Data 保留、启用、操作、排错、禁用与回滚。

## 框架文件归属

保留 Nexus 提供的 DLL、UE4SS-settings.ini、mods.txt/mods.json、Mods/shared，以及 FName_Constructor.lua、GNatives.lua、ProcessLocalScriptFunction.lua 三份签名。它们属于配套游戏适配，本组件不会写入这些位置。

beta.5 曾附带一个不同实现的兼容签名；旧附件保持原哈希。使用旧 ZIP 时只能复制 Mods/FFWJokerInfo 子目录。beta.6 不再携带该签名，不需要再额外覆盖 Nexus 文件。

迁移前备份整套框架及各 Mod Data/配置到 Mods 之外。不要将旧全局设置、签名或共享辅助库整份盖回新的 Nexus 安装。数据恢复按各组件版本说明进行；真实存档保持原位。

## 来源与核验范围

[UE4SS 上游源码](https://github.com/UE4SS-RE/RE-UE4SS)保留为来源说明，玩家安装入口采用上述 Nexus 适配包。加载是否成功取决于版本、签名和配置组合。

已检查实际 Nexus ZIP，SHA-256：87c1d83576e43324c2310f8a7fd3961d71dcab07d75f4b1fbf3bb0c2c226b375。归档包含 24 个文件。此摘要对应本次基线，不适用于作者后续更新。

卡牌内容包使用共享安装契约，在隔离目录检查原框架与模拟 Data 保留。此文件检查不代替实机运行、真实局域网/IP直连或全部 Windows 路径编码验证。不需要更改系统区域、驱动或图形设置。
