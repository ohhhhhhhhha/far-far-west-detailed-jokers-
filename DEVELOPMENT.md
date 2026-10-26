# Development / 开发说明

This is the standalone FFWJokerInfo repository. Runtime Lua files are stored in FFWTools/src/FFWJokerInfo/Scripts, including all calculation and language dependencies.

The root package.mjs exports buildRelease({ root, outputDirectory, JSZip }). It uses package-manifest.json as the explicit file allowlist and release.json for the version. Node.js and JSZip 3.10.1 are development dependencies declared in package.json. The API creates one runtime ZIP, one source ZIP, SHA256SUMS.txt and release-manifest.json. It neither launches the game nor uploads files.

Existing Lua checks are under FFWTools/tests. Their paths were adapted to this standalone layout; the runtime Lua and GUI payload remain unchanged. Package verification checks module/file closure, relative links, privacy, CRC/SHA-256 and equality with the accepted runtime. Run Lua checks with the repository as working directory in a Lua-capable IDE or runner when changing functionality. Player installation needs no terminal or script.

Follow [UE4SS’s Lua layout](https://docs.ue4ss.com/guides/creating-a-lua-mod.html) and [activation behavior](https://docs.ue4ss.com/guides/installing-a-c%2B%2B-mod.html). UE5LuaModKit is a [community reference](https://github.com/qycnet/UE5LuaModKit) for organization; its generic mod.lua/RegisterMod examples are not the UE4SS API contract. Validate game calls against the supported version.

本仓库为独立组件，所需共享文件已直接纳入自身 Scripts 目录。package.mjs 通过明确文件清单生成本组件运行包、源码包与校验文件，不启动游戏、不上传文件。既有测试路径已适配此布局，运行代码保持不变；玩家安装无需命令行。功能改动需运行相关 Lua/C# 检查，原生行为另行在游戏内验证。
