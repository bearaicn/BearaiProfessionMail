# 数据来源与第三方声明 / Data and third-party notices

本项目代码采用 MIT。`data-sources/wago` 中的 CSV 是从 [wago.tools](https://wago.tools) 获取的 Blizzard 游戏客户端 DB2 事实记录；`Data/Generated` 和 `data-sources/normalized` 是从这些记录整理的物品 ID、专业 ID、法术 ID 与消耗数量关系。Blizzard 的游戏内容、商标与相关权利仍属于其权利人；本项目 MIT 声明不授予这些第三方内容的权利，也不声称 wago.tools 数据有独立的 MIT 许可。

Project code is MIT licensed. The CSV snapshots from wago.tools contain factual records from Blizzard client DB2 tables. Generated files express item/profession/spell IDs and reagent quantities. Game content and trademarks remain with their respective owners; this project's MIT license does not grant rights in third-party content or assert an MIT license for wago.tools data.

本次运行时索引未嵌入第三方 Lua 库代码。数据表、构建版本、取得时间和 SHA-256 见源码仓库的 `data-sources/manifest.json`。输入表为 `SkillLineAbility` 和 `SpellReagents`；获取时明确指定客户端完整构建号。

No third-party Lua library implementation is embedded in the runtime index. The source manifest records exact requested builds, retrieval times, source URLs and SHA-256 hashes.

研究参考：

- [LibCrafts-1.0](https://github.com/refaim/LibCrafts-1.0)，MIT，Copyright (c) 2024 Roman Kharitonov。本地通过 github-kb 取得参考版本 `e0cc17e13307ac0fc4bfd469b1e4d145b9eb6194`，未复制其数据库或实现。
- [LibProfessionDB v1.9.1](https://www.curseforge.com/wow/addons/libprofessiondb/files/9095167)，MIT，Copyright (c) 2026 Pimptasty。用于核对 DB2 数据处理方法；未将其数据复制入运行时。其公开包未提供时光服 3.80.2 专用树，因此本次采用三客户端各自构建的原始 DB2 表。

These projects were consulted as references only. They are not runtime dependencies.
