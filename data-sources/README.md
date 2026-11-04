# 专业材料数据维护

0.5.0 增加运行时二次分类：`Data/ItemCategories.lua` 维护游戏类／子类的显示映射，`Modules/ItemClassifier.lua` 负责类别兜底；原始字段由客户端物品API实时提供，不来自外部配方库。分类不写入SavedVariables、不推断专业。未知子类回退大类；当前三客户端共享映射，若实测枚举不同，应增加明确的客户端差异而不是猜测用途。

运行时只按当前背包物品 ID 查索引，名称、图标、数量和 Tooltip 继续由游戏 API 提供。源表不是全部物品数据库；只需足够的专业／配方／消耗材料关系。

## 文件与优先级

| 位置 | 用途 | 是否进入安装包 |
| --- | --- | --- |
| `config/clients.json` | 目标客户端与完整构建号 | 否 |
| `data-sources/manifest.json` | 来源、取得时间、原始文件 SHA-256 | 否 |
| `data-sources/wago/{flavor}/*.csv` | 原始 SkillLineAbility、SpellReagents 快照 | 否 |
| `data-sources/normalized/{flavor}.json` | 专业 ID、法术 ID、消耗物品及数量 | 否 |
| `data-sources/coverage.json` | 每客户端和每专业统计、已知限制 | 否 |
| `Data/Professions.lua` | 专业目录与本地化显示名称 | 是 |
| `Data/MaterialData.lua` | 数据加载与扩充接口 | 是 |
| `Data/Generated/{flavor}.lua` | 自动生成物品 → 多专业索引 | 是 |
| `Data/Overrides/Common.lua`、`Titan.lua` | 人工补充的旧世用品、选矿、研磨等关系 | 是 |
| SavedVariables `rules` | 玩家覆盖；空表为专业匹配排除，nil 恢复内置 | 游戏自行保存 |

运行时顺序：专业目录 → 加载接口 → 对应客户端生成索引 → 维护者补充 → 玩家覆盖。生成文件在创建表之前检查客户端，其他客户端数据不会合并。数据库结构仍为 schema 1，无角色数据迁移。

人工补充是单独维护的已知关系，不参与源数据统计，不代表经过本次逐配方的游戏验收。发现错误可修正此层；不要直接改生成文件。新增专业还应同步检查专业目录、生成器支持的 skillLine ID、UI 和兼容层。

## 更新步骤

1. 先实际核对客户端构建，更新 `config/clients.json`；不能仅改变 TOC 就宣称覆盖新版本。
2. 在项目根目录运行 `pwsh -File scripts/data/Fetch-Sources.ps1`，联网获取对应构建的两个表。全部下载成功后更新快照和清单，不进行模糊版本回退。
3. 运行 `npm run data:build`，离线校验源文件哈希和结构，生成整理 JSON、覆盖统计与 Lua。
4. 检查统计变化与代表性物品，更新中英文 README 的数据日期、构建和数量。原始 CSV 并不能证明配方已开放。
5. 运行 `npm test` 与 `pwsh -File scripts/Test-Deployment.ps1`；打包时再执行 Package/Test-Packages。游戏内验证单独记录。

`npm run data:check` 不联网、不改文件：检查所有源文件 SHA-256，并验证重新生成的结果与提交文件完全一致。`npm test` 包含该检查。

## 生成方法与边界

- 以 SkillLineAbility 的 `Spell` 和 SpellReagents 的 `SpellID` 连接，以 `SkillLine` 确定专业。
- 只保留支持的专业和正数材料 ID／数量。同一专业／法术去重，同一材料合并多个专业，输出按数字排序。
- 解析 CSV 时支持引号、转义引号、换行与无限服额外的文本列；不执行下载的 Lua 或其他代码。
- 统计称为“有消耗材料的专业法术关系”，不把无材料技能、学技能的法术计为配方。客户端的隐藏／未开放记录仍可能进入，尚无服务器开放状态过滤。
- 选矿／研磨的通用技能不直接列出全部合法输入，需要维护者补充。采集产物不自动当成采集专业消耗材料。
- 每个 flavor 使用独立源表；若未来有服务器特有规则，可增加带 flavor／规则集检查的补充模块，并在 TOC 中安排到生成文件之后。

来源与权利说明见仓库根目录 `THIRD_PARTY_NOTICES.md`。当前数据来自指定构建的 wago.tools DB2 导出，不以“开源代码库的 MIT”替代游戏内容的来源说明。
