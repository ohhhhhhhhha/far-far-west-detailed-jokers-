# Far Far West — 更详细的奇术卡效果

[English](README.md) · [下载](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/releases/tag/v0.3.0-beta.5) · [反馈问题](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/issues)

**FFWJokerInfo · 0.3.0-beta.5 · UE4SS · Windows x64**

在原版奇术卡获得界面和 Tab 悬停详情中追加计算后的效果。F7 提供完整规则和实时读数，中英文跟随游戏语言切换。

## 生命周期与显示修复

切换世界、本地控制器或角色上下文时关闭 F7；加载完成后重新按 F7 创建面板。旧世界或旧模块实例中排队的操作会被丢弃。短暂无角色时保留同世界的原描述恢复记录。列表保持单行，选中不再改变文字宽度，并按视口和 DPI 调整每页条目数。

## 卡面显示规则

- 获得界面只显示相关变化，以“当前 → 获得后”表示；已持有卡牌显示当前总效果，达到效果上限时也保留当前值。
- 条件加成会注明触发条件。弹跳弹丸即使在地面也预览 ×1 → ×1.15，第二张为 ×1.15 → ×1.3；这是离地时的武器伤害倍率。
- 零资源暂时掩盖效果时，适用卡牌显示注明条件的触发数值或增长比例。
- 红色“无加成”仅用于获得预览。当前武器不在卡牌适用名单中时，仍显示“无加成”；普通拳击不会绕过特定武器的限制。
- 尖刺反伤显示固定加值、反伤公式和生命受伤触发条件，不再用尚未发生的受伤事件读数占满卡面。
- 原卡面不显示卡牌张数、叠加说明和上限说明；F7 保留份数、叠加规则、上限及事件相关读数。

描述左对齐、自动换行，长内容可滚动。例如，仅两张轻盈体态且无其他重力修正时，重力系数为 1.15，相对基础 1.25 降低 8%，不能把原文百分比直接相加。

## 安装与更新

验证基线为游戏 0.3.0.7、UE4SS build 1181。请先安装兼容的[官方 UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)，再复制随包游戏签名，**完成后才首次启动游戏**。详见[兼容性范围](UE4SS-COMPATIBILITY.zh-CN.md)。

1. 完全退出游戏，下载 [FFWJokerInfo-0.3.0-beta.5.zip](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/releases/download/v0.3.0-beta.5/FFWJokerInfo-0.3.0-beta.5.zip)。
2. 在游戏目录之外解压。
3. 在 Steam → 管理 → 浏览本地文件打开游戏目录，将 GameRoot 内的内容复制进去，覆盖本 Mod 的旧文件。
4. 重新启动游戏；仅回到标题界面不会重新加载 Lua 模块。

安装不需要终端或批处理。详见[安装、更新与卸载说明](INSTALL.zh-CN.md)。

## 操作

F7 开关完整详情。鼠标可以选择、翻页和关闭，滚轮滚动详情；F5/F6 切换条目，Shift + F5/F6 翻页。关闭后恢复镜头操作。

## 源码与验证

本仓库和下载包仅包含奇术卡说明组件及所需依赖，只读取并显示信息。刷卡、修改器、战斗统计属于其他独立组件。

源码和回归测试位于 FFWTools。审查覆盖 183 条卡牌／升级数据、28 条保留曲线，以及 27,600 组描述场景。生命周期、主机／客机和 DPI 行为已有离线回归验证；完整联机切图与 Slate 实际像素仍待实机验收。这些改动不能证明原生访问冲突 B07/B08 的原因或修复结果。详见[开发说明](DEVELOPMENT.md)和[更新记录](CHANGELOG.md)。

## 反馈与许可

通过 [GitHub Issues](https://github.com/ohhhhhhhhha/far-far-west-detailed-jokers-/issues) 提供 Mod、游戏、UE4SS 版本，准确的武器和卡牌名称、复现步骤与相关报错。请勿附带存档、账号标识或个人路径。

原创代码及文档采用 [MIT 许可](LICENSE)。游戏文本与数据保留原权利，详见[第三方声明](THIRD-PARTY-NOTICES.md)。
