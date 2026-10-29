# Detailed Joker Effects 安装、迁移与排错

适用组件：FFWJokerInfo 0.3.0-beta.7。更新日期：2026-10-29。此版修复 F7 视口脱离，减少闲置轮询，并读取突刺当前游戏曲线；旧版发布附件保持原样。

## 1. 下载正确的两个包

- 玩家框架入口：[Nexus 2 — UE4SS for FarFarWest](https://www.nexusmods.com/farfarwest/mods/2)。选择作者 anro / AnroG772 的 Frostburn / UE 5.8 玩家包；作者描述中的玩家包名为 **UE4SS-FarFarWest-v3.0.1-1183-frostburn.zip**；本次实际核对的是 Main 文件 **UE4SS-FarFarWest**，版本 **3.0.1.1183**、文件 ID **242**。Nexus 可能给下载名添加编号。普通玩家不需要 zDEV 开发包。
- 卡牌组件：[Nexus 115 — Detailed Joker Effects](https://www.nexusmods.com/farfarwest/mods/115) 的 Main 运行包，或 [GitHub beta.6 运行 ZIP](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/releases/download/v0.3.0-beta.7/FFWJokerInfo-0.3.0-beta.7.zip)。SOURCE 源码 ZIP 不用于游戏安装。

使用 Nexus 2 的游戏专用包，它包含本游戏所需的签名与配置。GitHub UE4SS 项目保留为框架上游来源。

## 2. 找到正确目录

在 Steam 库中右键 Far Far West → 管理 → 浏览本地文件。打开的是包含 **FarFarWest.exe** 的游戏根目录；从这里继续进入 **FarFarWest/Binaries/Win64**，看到 **FarFarWest-Win64-Shipping.exe** 后才是框架安装位置。

最终目录应类似下列结构。框架文件来自 Nexus 专用包，不能用卡牌包里的其他文件覆盖它们。

~~~text
<Steam 打开的游戏根目录>/
├─ FarFarWest.exe                              游戏已有
└─ FarFarWest/
   └─ Binaries/
      └─ Win64/
         ├─ FarFarWest-Win64-Shipping.exe       游戏已有
         ├─ dwmapi.dll                         Nexus 框架提供
         └─ ue4ss/
            ├─ UE4SS.dll                       Nexus 框架提供
            ├─ UE4SS-settings.ini              保留 Nexus 配置
            ├─ UE4SS_Signatures/               保留 Nexus 的整套签名
            ├─ UE4SS.log                       启动后产生
            └─ Mods/
               ├─ mods.txt                    保留原有配置
               ├─ shared/                     保留框架辅助库
               └─ FFWJokerInfo/
                  ├─ enabled.txt              空文件也正常
                  └─ Scripts/
                     ├─ main.lua
                     ├─ Scope.lua
                     ├─ Panel.lua
                     └─ 其余随包 Lua 文件
~~~

不要放成 Win64/Win64、ue4ss/ue4ss 或 FFWJokerInfo/FFWJokerInfo/Scripts。外层游戏目录和内部 FarFarWest 子目录同名是正常结构，不要据此少放或多放一层。

## 3. 已装过旧框架：先备份，再迁移

已有正常运行的 Nexus Frostburn 框架时，可跳到第 5 节只更新卡牌。

1. 完全退出游戏；只退回标题界面不够。
2. 用文件资源管理器，把现有 ue4ss 整个目录、当前框架提供的 dwmapi.dll 复制到游戏目录之外的备份目录。备份目录不要放在 ue4ss/Mods 内，避免旧 Mod 再次被自动加载。
3. 单独确认各 Mod 的 **`Mods/<Mod名称>/Data/`** 已保存在备份中；同时保留各 Mod 自己的配置和原 mods.txt。Data 可能包含统计记录或组件配置，它不等于游戏存档。真实存档保持原位，不要删除或改写。
4. 确认备份确实存在后，将旧 ue4ss 和已确认属于旧框架的 dwmapi.dll 移出活动 Win64 目录，放入另一个带日期的隔离目录，腾出干净安装位置；不要覆盖已有备份。不要不备份就删除整个 ue4ss，也不要处理无法确认归属的其他代理 DLL。
5. 按第 4 节安装完整 Nexus 玩家框架。不要把旧 UE4SS-settings.ini、旧 DLL、旧共享辅助库或旧签名整份盖回去，以免把旧引擎版本设置或不匹配扫描规则带回来。
6. 重新安装所需 Mod 的兼容版本，再依据各组件的升级说明恢复对应 Data。不要用“还原 Data”为由把整个旧 Mods 目录覆盖新框架。尚未恢复的数据继续保留在备份里。

## 4. 首次安装 Nexus 游戏专用框架

1. 在游戏目录之外解压 Nexus 2 的玩家包。
2. 从解压结果中找到 dwmapi.dll 和 ue4ss 目录，将它们放入第 2 节的 Win64 目录。不要把下载 ZIP 的外层同名包装文件夹也复制进去。
3. 保持该包的 DLL、UE4SS-settings.ini、Mods/shared 和 UE4SS_Signatures 配套。框架作者提供的 FName、GNatives、ProcessLocalScriptFunction 等文件属于这套适配；不要按旧卡牌指南任意删除或替换。
4. 框架与它自己的配置、签名均到位后再启动。可先单独验证能进入标题或大厅，然后完全退出游戏再装卡牌。

启动异常时，检查 ue4ss/UE4SS.log 中的最终错误。游戏更新后，按 Nexus 2 作者的说明核对适配版本。

## 5. 安装卡牌组件

beta.7 的 GameRoot 仅包含 FFWJokerInfo 的 14 个文件，不包含框架 DLL、设置、共享辅助库或签名。先完成 Nexus 框架安装，再安装此内容包。

1. 完全退出游戏，在游戏目录之外解压 FFWJokerInfo-0.3.0-beta.7.zip。
2. 打开卡牌包的 **GameRoot** 文件夹，把里面的 **FarFarWest** 文件夹复制到 Steam“浏览本地文件”打开的游戏根目录，与同名目录合并。此目标旁边应有 **FarFarWest.exe**。
3. 不要把 GameRoot 文件夹本身复制进去，也不要把整份内容复制到内部 Win64。框架落点与内容包落点不同。
4. 合并后的入口应为：

   FarFarWest/Binaries/Win64/ue4ss/Mods/FFWJokerInfo/Scripts/main.lua

5. 只替换本组件自身的代码和 enabled.txt；更新前先备份，保留已有 Data/配置及其他 Mod。
6. 若选择手动安装单个目录，也可把包内 GameRoot/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWJokerInfo 复制到游戏的 ue4ss/Mods 中，结果相同。

Nexus 的 UE4SS_Signatures、UE4SS-settings.ini、mods.txt/mods.json、Mods/shared 与 DLL 保持原样。此卡牌包不再提供额外框架签名。

**旧包注意：** 已发布的 beta.5 ZIP 含有一份旧兼容签名。使用该旧包时只能复制它的 Mods/FFWJokerInfo 子目录，不能照旧说明合并全部 GameRoot。beta.5 原附件没有被替换。

## 6. 启用与首次验证

- 检查 Mods/FFWJokerInfo/enabled.txt 存在，空文件就是正常的启用标记；Scripts/main.lua 与其他 Lua 文件应在同一套目录中。
- 本包已含 enabled.txt，通常不需要再写 mods.txt。若按所用框架文档使用 mods.txt，只编辑 FFWJokerInfo 自己的条目，不替换整份文件。条目形式是 FFWJokerInfo : 1。
- 在文件资源管理器中显示文件扩展名，排除 enabled.txt.txt 或 main.lua.txt。
- 完整启动游戏，进入大厅后按 F7。窗口必须有焦点；使用笔记本功能键模式时可能需要 Fn+F7。
- 能看到面板后，用鼠标选卡、翻页、滚动详情、关闭，再确认镜头控制恢复。任务内查看获得界面和 Tab 卡牌悬停详情。

此前 beta.5/6 基线已确认单人 F7、鼠标和返回标题正常。beta.7 需重做这些检查，并验证关闭原生菜单后 F7 能否重新显示。真实局域网/IP直连的性能仍需实机对照。

## 7. 操作方式

| 操作 | 功能 |
| --- | --- |
| F7 | 打开／关闭完整卡牌详情 |
| 鼠标左键 | 选择条目、前后翻页、关闭 |
| 滚轮 | 在详情区域滚动长内容 |
| F5 / F6 | 上一项／下一项 |
| Shift + F5 / F6 | 上一页／下一页；页容量随窗口和 DPI 调整 |
| 换图后重新按 F7 | 创建当前世界的新面板 |

原版获得界面和 Tab 悬停说明自动增强，不需要一直打开 F7。卡牌信息依照当前武器适用名单；获得预览中不适用时显示红色“无加成”。F2 的资源修改属于独立修改器，F8 属于统计组件。

## 8. 更新本组件

1. 完全退出游戏，备份 Mods/FFWJokerInfo 到 Mods 之外。
2. 保留其中任何用户配置和 Data（若存在），也不动其他 Mod 的 Data。
3. 只用新卡牌包替换 FFWJokerInfo 的代码和启用标记；不要借此重装或覆盖 Nexus 框架。
4. 若从很早的混合版本升级，旧 FFWJokerInfo/Scripts/Spawner.lua 已迁移到独立修改器。确认备份后按版本说明移走该旧文件，避免混合新旧职责。
5. 完整重启，重做第 6 节的短检查。不要同时保留两个带 enabled.txt 的卡牌副本在 Mods 里。

beta.7 沿用 beta.6 的独立内容包结构。所有已发布旧版 ZIP 保持原哈希；不要从旧包补回签名。

## 9. 常见问题

| 现象 | 检查顺序 |
| --- | --- |
| 启动就崩溃或停在对象构造等待 | 依次核对 Nexus 2 的 Frostburn 玩家包、Shipping.exe 所在的 Win64 目录，以及 DLL、设置和签名是否来自同一套框架。再查看 ue4ss/UE4SS.log 的最终错误，并核对游戏与框架版本。 |
| 没有 ue4ss/UE4SS.log | 检查 dwmapi.dll 与 Shipping.exe 是否同目录，以及是否解压多了一层；这时优先排查加载器是否加载。 |
| 日志有框架启动但没有 FFWJokerInfo loaded | 检查 Mod 目录、完整 Lua 文件、enabled.txt 文件名和重复副本；别只改 mods.txt 却留下另一份启用标记。 |
| 有 loaded 日志，F7 没出现 | 完整重启后进入大厅／任务并让游戏取得焦点；标题和加载阶段不显示。随后查看日志中对应的 FFWJokerInfo 错误。 |
| 选卡文字不完整 | 先确认版本和窗口/DPI；列表使用单行省略，完整信息在标题及详情内。异常换行、按钮越界再报告分辨率、缩放和具体条目。 |
| 换图后面板关闭 | 属于设计行为；角色就绪后重新按 F7。若重新打开失败，再记录对应日志。 |
| 修改器 F2 打开但不能修改 | 记录 F2 的具体提示，按独立修改器的说明检查当前游戏位置、写入条件及应用结果。 |
| 非 ASCII 路径加载失败 | 检查日志路径错误；必要时通过 Steam 的“存储空间／移动安装”测试 ASCII 库目录。不要改系统区域、注册表或调用全局 Lua locale。此前 Node 解压与 Lua VFS成功不代表全部 Windows 编码环境已验收。 |

反馈时提供 Mod、游戏、框架版本、准确卡名/武器名、单人或局域网/IP直连、复现步骤及相关错误行。遮住账号、IP、个人路径；不要上传真实存档、整个 Data 或未经处理的转储。

## 10. 禁用、回滚与保留数据

- 最直接的禁用方式：退出游戏，将整个 FFWJokerInfo 文件夹移到 Mods 外的备份目录。只在 Mods 里改名未必禁用，因为其中的 enabled.txt 仍可能被发现。
- 如果保留目录：把 enabled.txt 移走，并将 mods.txt 中已有的 FFWJokerInfo 条目设为 0。启用标记可能优先于名单，不能只改其中一处。
- 回滚卡牌：退出游戏，先把当前整个 FFWJokerInfo 目录移到 Mods 外保存，再把备份版本放回原位置，避免新旧脚本混装。按该版本说明恢复兼容的配置/Data；未恢复的数据继续保留。随后完整重启。
- 回滚框架：先备份当前所有 Mod 的 Data/配置，将当前框架移出活动 Win64 目录，再恢复迁移前完整、配套的框架备份。按各组件说明恢复兼容的 Data；未恢复的数据继续保存。真实存档保持原位。
- 卡牌禁用或回滚不需要删除 Nexus 框架的共享签名。其他 Mod 仍依赖它们。

参见 [框架依赖与签名策略](UE4SS-COMPATIBILITY.zh-CN.md)。
