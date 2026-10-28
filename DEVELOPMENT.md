# Development / 开发说明

This is the standalone FFWJokerInfo repository. Runtime Lua files are stored in FFWTools/src/FFWJokerInfo/Scripts, including all calculation and language dependencies.

The root package.mjs exports buildRelease({ root, outputDirectory, JSZip }). It uses package-manifest.json as the explicit file allowlist and release.json for the version. Node.js and JSZip 3.10.1 are development dependencies declared in package.json. The API creates one runtime ZIP, one source ZIP, SHA256SUMS.txt and release-manifest.json. It neither launches the game nor uploads files.

Existing Lua checks are under FFWTools/tests. Their paths are adapted to this standalone layout. Json.lua under tests supports synthetic fixture comparisons and is not part of the runtime ZIP. Package verification checks module/file closure, relative links, privacy, CRC/SHA-256 and equality with the tested staged runtime. Run Lua checks with the repository as working directory in a Lua-capable IDE or runner when changing functionality. Player installation needs no terminal or script.

Follow [UE4SS’s Lua layout](https://docs.ue4ss.com/guides/creating-a-lua-mod.html) and [activation behavior](https://docs.ue4ss.com/guides/installing-a-c%2B%2B-mod.html). UE5LuaModKit is a [community reference](https://github.com/qycnet/UE5LuaModKit) for organization; its generic mod.lua/RegisterMod examples are not the UE4SS API contract. Validate game calls against the supported version.

本仓库为独立组件，所需共享文件已直接纳入自身 Scripts 目录。package.mjs 通过明确文件清单生成本组件运行包、源码包与校验文件，不启动游戏、不上传文件。测试路径已适配此布局，tests/Json.lua 仅用于合成数据检查，不进入运行包；玩家安装无需命令行。功能改动需运行相关 Lua 检查，原生行为另行在游戏内验证。

## Release publishing / 发布附件

The GitHub workflow publishes explicitly prepared artifacts from publish/* branches through the official GitHub JavaScript API. It verifies SHA-256 and size before publishing the release. Its token is limited to repository contents; it uses no shell commands and does not build or run the game. Publication payload files live only on the upload branch, not on main or in the source archive.

GitHub 工作流从 publish/* 分支读取已准备的附件，通过官方 JavaScript API 校验并发布 Release。只使用仓库内容权限，不运行批处理、命令行或游戏；上传载荷不进入 main 和源码包。

## Nexus archive contract / Nexus 安装契约

FFWTools/tests/runtime_archive_test.mjs exports verifyNexusRuntimeArchive({ archive, frameworkRoot, JSZip, destination }). Supply the runtime ZIP, an extracted Nexus 2 player framework and a new isolated destination. The contract stages the real framework, refuses any content-file overwrite of it, preserves synthetic existing Data and requires the framework-owned startup signature. Use this Nexus function for beta.6; the legacy verifyRuntimeArchive function describes older archives with bundled signatures. No installed game files or real Data are needed.

本版使用 verifyNexusRuntimeArchive 检查新内容包。frameworkRoot 指向解压后的 Nexus 玩家框架，destination 使用隔离测试目录；禁止把真实游戏安装目录当作验证目标。未修改卡牌 Lua 时，用逐文件字节相等验证复用 beta.5 的功能测试证据；修改功能后另行运行相应 Lua 回归。
