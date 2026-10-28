# 安装、更新与卸载

## 首次安装

1. 完全退出游戏。通过 Steam 的“管理 → 浏览本地文件”确定游戏目录。
2. 单独安装兼容的官方 UE4SS；本候选包不替换加载器 DLL 或配置。
3. 解压本包，将 GameRoot 内的内容合并到游戏目录。确认签名位于 FarFarWest/Binaries/Win64/ue4ss/UE4SS_Signatures/ProcessLocalScriptFunction.lua，卡牌模块位于同级 Mods/FFWJokerInfo。
4. **框架与本游戏签名都已安装后，再首次启动游戏。** 在大厅按 F7 检查面板。换图后重新按 F7 重建。

不需要终端或批处理。不要覆盖已有的 UE4SS-settings.ini、mods.txt、玩家 Data 或存档。模块的 enabled.txt 用于激活；仍应遵循所用官方框架版本的启用规则。

## 更新

退出游戏后备份现有 FFWJokerInfo 目录和同名签名文件，再合并新版 GameRoot。完整重启游戏；仅返回标题界面不会重载脚本。旧版本若仍含 Scripts/Spawner.lua，可移除该已迁移到独立修改器的旧文件。

## 不同电脑与路径

显示尺寸按游戏视口及 DPI 计算。离线模型已覆盖常用分辨率和缩放，但不能代替本机字体的实际像素验收。

发布检查包括 Node 实际解压到中文和空格目录，以及 Lua 虚拟文件系统测试。UE4SS 1181 的 Lua 文件加载使用 narrow fopen，因此这些结果**不能证明所有 Windows 系统区域编码下的非 ASCII 路径均可加载**。遇到此类问题时，先检查 UE4SS 日志中的脚本路径错误；可通过 Steam 设置中的“存储空间”添加只含 ASCII 字符的库目录，再使用 Steam 的移动游戏功能测试。无需修改系统区域、注册表或全局 Lua locale。

## 卸载与回滚

退出游戏后删除或移走 Mods/FFWJokerInfo 即可停用本组件。不要删除仍由其他 Mod 使用的共享签名。回滚时恢复本组件及签名的备份，保持其他 Mod、Data 和官方框架配置不变。

详见 [UE4SS 兼容性说明](UE4SS-COMPATIBILITY.zh-CN.md)。
