# Far Far West — 更详细的奇术卡资料

[English](README.md) · [下载](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/releases/tag/v0.3.0-beta.3) · [问题反馈](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/issues)

**FFWJokerInfo · 0.3.0-beta.3 · UE4SS · Windows x64**

- 在原奇术卡描述、拾取界面及 Tab 悬停详情中追加当前效果和拾取预览。
- 原卡面只显示相关、会变化的数值，不显示当前张数、叠加标记或上限脚注。
- 确认没有实际加成时显示红字“无加成”；缺失输入仍标为待读取，不当作零。
- F7 保留张数、叠加规则、上限和条件等完整详情。
- 随游戏切换中英文；支持鼠标选择、翻页、滚动和关闭，无需先按 Esc。

例如在当前基线下，仅有两张“轻盈体态”时重力为 1.15，相对基础 1.25 降低 8%，不能把描述百分比直接相加。本组件只显示信息，不刷卡、不修改进度。

## 安装

验证基线为 Far Far West 0.3.0.7 和 UE4SS build 1181。请另行安装兼容的 [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)。

1. 退出游戏，下载 [FFWJokerInfo-0.3.0-beta.3.zip](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/releases/download/v0.3.0-beta.3/FFWJokerInfo-0.3.0-beta.3.zip)。
2. 解压到游戏目录之外。
3. 从 Steam → 管理 → 浏览本地文件打开游戏目录，将 GameRoot 内的内容复制进去。
4. 在游戏中按 F7 打开完整详情。

无需终端或安装脚本。更新旧版前请先阅读[安装、升级与卸载说明](INSTALL.zh-CN.md)。

## 操作

F7 打开或关闭详情；鼠标选择、翻页、关闭，滚轮滚动详情。F5/F6 切换条目，Shift + F5/F6 翻页。关闭后恢复镜头操作。

## 源码与验证

本仓库只包含更详细的奇术卡资料及其必要依赖，不包含另一工具或战斗统计/同步 Mod。所需的计算与语言文件随源码独立提供，不依赖另一个仓库。

Lua 源码位于 FFWTools/src/FFWJokerInfo/Scripts。详见[开发说明](DEVELOPMENT.md)及[更新记录](CHANGELOG.md)。0.3.0-beta.3 的仓库拆分保持已确认有效的运行内容不变；离线检查不代表每一种组合都经过游戏内实测。

## 反馈与许可

由 FFWTools contributors 维护。请在 [GitHub Issues](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/issues) 提供工具版本、游戏及 UE4SS 版本、复现步骤和相关错误文字；勿附存档、账号标识或个人路径。

原创代码和文档采用 [MIT 许可](LICENSE)。游戏来源文本和数据保留原权利归属，详见[来源与授权说明](THIRD-PARTY-NOTICES.md)。
