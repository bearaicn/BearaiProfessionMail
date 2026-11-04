# BearaiProfessionMail

专业材料邮寄助手，版本 `0.1.0`。共享 Lua 业务代码，通过运行时能力检测适配经典旧世和无限服。

当前状态：已实现第一阶段及背包扫描、材料匹配、真实槽位拖拽；已完成本机语法与模拟测试，**尚未完成游戏内验收**。

## 使用

1. 安装后登录每个本账号角色，自动记录角色名、服务器、职业和已学专业；数据在同账号、同客户端角色间共享。
2. 打开原生邮箱，点击右上角「专业材料」。再次点击或点击助手关闭按钮收起；关闭邮箱同时隐藏助手。
3. 用「上个角色／下个角色」选择收件角色，或通过「添加」录入其他账号角色及专业。手动角色支持修改和两次点击确认删除；自动记录的角色不允许手动覆盖。
4. 默认在**切换目标角色时**填写原生收件人；可取消勾选此选项。填入后玩家仍可修改，材料刷新不会覆盖收件人。
5. 切到原生「发送邮件」页，从列表拖拽材料图标至原生附件栏。每行是一个真实背包槽位与堆叠，不合并同名材料；无需打开背包。
6. 检查原生收件人、附件和邮资，自行点击原生发送按钮。

选择目标只决定材料筛选。手动改收件人后不会反向改变筛选目标，请以原生收件人作为最终发送依据。跨服或跨阵营邮寄、硬核服邮寄限制及附件容量由游戏决定。

`/bpm` 在邮箱打开时切换助手；`/bpm diag` 输出版本、Interface 和 API 能力。

## 专业和材料

包含旧世九个主要专业，以及烹饪、钓鱼、急救。角色允许多个专业；采集专业不会自动匹配其产出的所有材料：例如矿石给采矿角色，鱼类主要给烹饪／炼金角色，鱼饵给钓鱼角色。草药学、剥皮没有消费材料规则时列表为空是正常现象。

`Data/ProfessionMaterials.lua` 是首批常见旧世材料的物品 ID → 专业集合，不是完整配方需求表，不考虑技能点、已学配方或具体需求数量，也未覆盖无限服专有材料。列表支持名称／ID 搜索、专业分类、分页、数量与真实背包 Tooltip；已知绑定物品隐藏，锁定物品显示但禁止拖拽。

「材料规则」输入物品 ID 后勾选专业并保存，覆盖该物品的内置归属；允许多选；全不选表示排除；「恢复内置规则」清除该物品的手动覆盖。规则在同客户端本账号共享。

## 开发与部署

客户端现场检查（2026-11-04）：

| 用途 | 本机目录 | EXE 版本 | TOC Interface |
| --- | --- | --- | --- |
| 经典旧世硬核服测试 | `D:\Games\World of Warcraft\_classic_era_` | 1.15.9.70576 | 11509 |
| 无限服目标 | `D:\Games\World of Warcraft\_forever_` | 1.60.1.70755 | 16001 |

版本来自本机 `.build.info` 和 EXE，Interface 同时与已安装插件声明交叉核对。安装路径不能证明当前账号角色是否属于硬核服。更新客户端后重新运行检查并在游戏 `/bpm diag` 核实。

在项目根目录执行 PowerShell：

```powershell
# 检查路径和版本
.\scripts\Inspect-Clients.ps1
# 默认只预览；没有 -Apply 不复制文件
.\scripts\Deploy.ps1 -Client Both
# 同步到经典旧世测试客户端
.\scripts\Deploy.ps1 -Client Hardcore -Apply
# 同步到无限服
.\scripts\Deploy.ps1 -Client Forever -Apply
# 也可 -Client Both -Apply，或 -GameRoot 指定其他安装根目录
```

脚本读取 `config/clients.json`，按目标生成独立 Interface 的 TOC，复制 TOC 列出的 Lua 并校验 SHA256，额外写入 `deployment.json` 记录插件版本、Git 来源、工作区状态及文件哈希（14 个插件文件 + 1 个来源记录）。不删除目标文件，不接触其他插件或 WTF/SavedVariables。覆盖同名本插件开发文件，部署前保留需要的旧版本；回滚时可从 Git 恢复源代码后再次部署。首次安装应完全退出并重新启动游戏，以便扫描新 TOC；后续 Lua 更新可 `/reload`。

Git 采用共享 `main` 主线，两套客户端分别配置、部署和验收，不使用两条长期环境分支。插件版本以 TOC 为准，客户端 Interface 和 SavedVariables schema 独立管理。详见 [环境与版本策略](docs/VERSIONING.md)。

```powershell
npm ci --ignore-scripts --registry=https://registry.npmjs.org
npm test
.\scripts\Test-Deployment.ps1
```

Node 只用于开发检查，不是插件运行依赖。部署不会包含 node_modules 或测试代码。Lua 5.1 语法检查使用 luaparse，行为测试使用 Fengari Lua VM 加最小 WoW API 模拟，因此不能证明真实受保护操作、视觉布局或服务器规则已通过。

## 数据与模块

`BearaiProfessionMailDB` 是账号级 SavedVariables，结构为 `schema=1 / profiles[era|forever] / characters,rules,settings`。两个客户端的数据隔离，不自动互相同步。专业按稳定 skillLine ID 保存，角色按「名称-服务器」索引。登录与 `SKILL_LINES_CHANGED` 更新当前角色；退出或 `/reload` 后由游戏落盘。未来数据版本拒绝加载，避免新版数据被旧插件覆盖。

Core 负责初始化、数据和兼容 API；Modules 负责角色、专业、背包、匹配及邮箱；UI 负责原生风格控件。使用 Lua 构造界面，无需额外 XML。专业兼容支持技能列表（含临时展开并恢复折叠标题）和稀疏 `GetProfessions` 返回；背包支持 `C_Container` 和旧全局 API。只扫描随身背包 0–4，不读取银行或其他角色的物品。

API 参考以 Blizzard UI 导出的源码为依据：[容器接口](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua)、[原生邮箱实现](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_UIPanels_Game/Classic/MailFrame.lua)、[经典技能面板](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_UIPanels_Game/Classic/SkillFrame.lua)。这些是可更新的上游参考，不能替代本机对应客户端的游戏验收。

后续入口：[开发进度](docs/PROGRESS.md)、[游戏测试清单](docs/TESTING.md)、[结构化记录](docs/progress.json)。
