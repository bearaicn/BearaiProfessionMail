<p align="center">
  <img src="docs/assets/readme-hero.jpg" alt="熊智专业邮寄助手 / BearAI Profession Mail" width="900">
</p>

<p align="center"><strong>简体中文</strong> · <a href="README.en.md">English</a></p>

# BearaiProfessionMail

熊智专业邮寄助手 / BearAI Profession Mail，版本 `0.3.2`。共享 Lua 业务代码，通过运行时能力检测适配经典旧世和无限服。

当前状态：已实现第一阶段及背包扫描、材料匹配、真实槽位拖拽；已完成本机语法与模拟测试，**尚未完成游戏内验收**。

## 使用

1. 安装后登录每个本账号角色，自动记录角色名、服务器、职业、等级和已学专业；数据在同账号、同客户端角色间共享，升级时更新等级。
2. 打开原生邮箱，点击底部标签旁的「材料」。空间不足时入口位于标签下方；再次点击或点击助手关闭按钮收起。关闭邮箱同时隐藏助手及下拉菜单。
3. 在角色表格中点击整行选择，可按角色、服务器、职业、专业搜索，用滚轮或箭头滚动。表格直接显示职业、等级和专业，服务器／来源显示在角色名下方。通过「添加」录入其他账号角色，职业和等级可选；旧记录缺失字段显示未知。手动角色支持修改和两次点击确认删除；自动角色不允许手动覆盖。
4. 默认在**切换目标角色时**填写原生收件人；可取消勾选此选项。填入后玩家仍可修改，材料刷新不会覆盖收件人。
5. 切到原生「发送邮件」页，双击背包格子将一堆物品放入附件，也可直接拖拽。下方独立附件区始终显示当前原生附件，右击撤回一堆；右击背包物品则撤回最后一个同类（相同物品链接）附件。每格保留真实背包槽位或附件序号，不合并同名堆叠。背包区为 22 格，超过后可滚轮或按钮翻页。
6. 检查原生收件人、附件和邮资，自行点击原生发送按钮。

选择目标只决定材料筛选。手动改收件人后不会反向改变筛选目标，请以原生收件人作为最终发送依据。跨服或跨阵营邮寄、硬核服邮寄限制及附件容量由游戏决定。

`/bpm` 在邮箱打开时切换助手；`/bpm diag` 输出版本、Interface 和 API 能力。

`/bpm settings` 打开设置页，也可在游戏设置 → 插件中找到「熊智专业邮寄助手 / BearAI Profession Mail」。设置页可在不开邮箱时搜索、添加、编辑、删除手动角色，或更新当前登录角色。设置页选择角色不会填写原生收件人。

账号数据边界：同一 WoW 账号、同一客户端下的角色共享 SavedVariables；插件只直接读取当前角色。其他本账号角色需登录后自动记录，退出或 /reload 时落盘，下次切角色读取更新数据；并非离线实时查询。WoW1／WoW2 等不同 WoW 账号不自动共享，同一战网账号也不代表共享。经典旧世与无限服分别保存。手动记录若与登录角色名称及服务器完全相同，登录后以游戏实测职业、等级、专业更新并转为本账号自动记录，不能再手动覆盖；服务器填错时不会自动合并。

## 专业和材料

包含旧世九个主要专业，以及烹饪、钓鱼、急救。角色允许多个专业；采集专业不会自动匹配其产出的所有材料：例如矿石给采矿角色，鱼类主要给烹饪／炼金角色，鱼饵给钓鱼角色。草药学、剥皮没有消费材料规则时列表为空是正常现象。

`Data/ProfessionMaterials.lua` 是首批常见旧世材料的物品 ID → 专业集合，不是完整配方需求表，不考虑技能点、已学配方或具体需求数量，也未覆盖无限服专有材料。列表支持名称／ID 搜索、专业分类、分页、数量与真实背包 Tooltip；已知绑定物品隐藏，锁定物品显示但禁止拖拽。

「材料规则」输入物品 ID 后勾选专业并保存，覆盖该物品的内置归属；允许多选；全不选表示排除；「恢复内置规则」清除该物品的手动覆盖。规则在同客户端本账号共享。

筛选下拉默认「按角色专业过滤」；还可选择「全部可邮寄物品」「全部材料」或任一独立专业。独立专业不受收件角色专业限制；切换到另一个角色时，任何材料类别筛选均重置为「按角色专业过滤」，并回到第一页。搜索与以上筛选叠加。全部材料按客户端物品类别（商品／材料）、制造原料标记及已知规则识别，允许尚未建立专业规则的原料出现。“全部可邮寄”是本地可判断的候选：排除绑定、任务物品等，收件人、跨服、账号绑定及服务器特有规则仍以原生邮箱为准；首版不放宽账号绑定物品。

双击／右击只处理玩家正在编辑的一封邮件中的一堆附件，不发送邮件，也不批量操作。附件栏满、战斗、鼠标已有物品、锁定、邮箱正在处理或附件身份变化时拦截。原生邮箱若拒绝添加且物品仍在鼠标上，请放回背包或手动拖到附件栏，不自动清除光标。

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

脚本读取 `config/clients.json`，按目标生成独立 Interface 的 TOC，复制 TOC 列出的 Lua 及 `config/assets.json` 中的资源并校验 SHA256，额外写入 `deployment.json` 记录插件版本、Git 来源、工作区状态及文件哈希（当前 18 个插件文件 + 1 个来源记录）。不删除目标文件，不接触其他插件或 WTF/SavedVariables。覆盖同名本插件开发文件，部署前保留需要的旧版本；回滚时可从 Git 恢复源代码后再次部署。首次安装、增加模块或纹理未被识别时完全退出并重启；仅更新已有 Lua 时可 `/reload`。

LOGO 为已认可熊头与信封图案的 128×128 缩小版：`Media/logo-bear-mail-v1.png` 为透明 PNG 参考（28,040 字节），`Media/Logo.tga` 为游戏使用的 32 位透明纹理（65,554 字节）。部署只包含 TGA，不携带 PNG、大尺寸原图或开发文件。`scripts/Prepare-Logo.ps1` 可从指定 `-Source` 重建透明 PNG 和 TGA；保持图案，仅进行高质量缩放与格式转换。

Git 采用共享 `main` 主线，两套客户端分别配置、部署和验收，不使用两条长期环境分支。插件版本以 TOC 为准，客户端 Interface 和 SavedVariables schema 独立管理。详见 [环境与版本策略](docs/VERSIONING.md)。

```powershell
npm ci --ignore-scripts --registry=https://registry.npmjs.org
npm test
.\scripts\Test-Deployment.ps1
```

Node 只用于开发检查，不是插件运行依赖。部署不会包含 node_modules 或测试代码。Lua 5.1 语法检查使用 luaparse，行为测试使用 Fengari Lua VM 加最小 WoW API 模拟，因此不能证明真实受保护操作、视觉布局或服务器规则已通过。

## 数据与模块

`BearaiProfessionMailDB` 是账号级 SavedVariables，结构为 `schema=1 / profiles[era|forever] / characters,rules,settings`。两个客户端的数据隔离，不自动互相同步。专业按稳定 skillLine ID 保存，角色按「名称-服务器」索引。登录与 `SKILL_LINES_CHANGED` 更新当前角色；退出或 `/reload` 后由游戏落盘。未来数据版本拒绝加载，避免新版数据被旧插件覆盖。

Core 负责初始化、数据和兼容 API；Modules 负责角色、专业、背包、匹配及邮箱；UI/Theme.lua 与 UI/Widgets.lua 提供独立深色主题和控件，不依赖露露工具箱或外部皮肤。窗口优先放在邮箱右侧，空间不足尝试左侧或屏幕内回退，可拖动顶部空白移动。使用 Lua 构造界面，无需额外 XML。专业兼容支持技能列表（含临时展开并恢复折叠标题）和稀疏 GetProfessions 返回；背包支持 C_Container 和旧全局 API。只扫描随身背包 0–4，不读取银行或其他角色的物品。schema 仍为 1，class／level 是可选字段，兼容旧记录。

API 参考以 Blizzard UI 导出的源码为依据：[容器接口](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua)、[原生邮箱实现](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_UIPanels_Game/Classic/MailFrame.lua)、[经典技能面板](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_UIPanels_Game/Classic/SkillFrame.lua)。这些是可更新的上游参考，不能替代本机对应客户端的游戏验收。

后续入口：[开发进度](docs/PROGRESS.md)、[游戏测试清单](docs/TESTING.md)、[结构化记录](docs/progress.json)。
