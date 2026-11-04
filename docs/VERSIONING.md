# Git、客户端环境与版本策略

## 当前开发与测试约定（2026-11-04 用户明确要求）

- 后续授权更新：0.5.6已分别部署三个客户端；本次用户明确要求提交并向GitHub、Gitee发布全部三个客户端包，使用v0.5.6新标签，发行标记为测试版，各客户端游戏验证状态分别注明。下方“仅时光服”和早期双客户端策略为历史阶段约定。

- 小修复递增第三段补丁号，例如 0.4.0 → 0.4.1；新增较大功能时再评估第二段版本号。每次交付测试需让安装版本可区分。
- 所有通用功能与修复面向 era（经典旧世／硬核服）、forever（无限服）、titan（时光服）共同维护；客户端差异进入兼容层、配置或数据层，不因当前只测试时光服而缩小兼容范围。
- 通用改动执行三客户端可运行范围内的自动验证；真实游戏验收分别记录，不能用时光服结果替代另外两种客户端。
- 近期仅向时光服部署／提供测试版本，由用户使用时光服验收；未经后续指示不更新其他客户端安装或对外新增其他客户端发布包。
- 本机部署直接更新，不创建旧插件备份。线上 Tag／Release 按明确的发布任务执行，不因本机部署自动创建。

## 开发主线

一个仓库维护同一套功能，以 `main` 为主线。功能需要隔离时使用短期 `feat/*`、`fix/*` 分支，完成验证后合并。经典旧世与无限服不建立长期环境分支；客户端差异在配置、兼容层和数据层表达，避免修复遗漏或双份代码漂移。

0.4.0 开发版新增 Titan（_classic_titan_，3.80.2 /38002，数据域 titan）。三客户端共用主线；Deploy/Package 支持 Titan 与 All，Both 仍仅为 Era＋Forever。时光服当前待游戏验证，不能仅修改 Interface 就宣称兼容。发布脚本可选择三种客户端，新增版本仍须创建新的不可变 Tag。

用户指定托管地址为 https://github.com/bearaicn/BearaiProfessionMail.git，使用 origin 和 main。提交前核对仓库、分支、远端和改动范围，禁止强推或覆盖已有历史。

## 双远端同步

- GitHub：`origin` 拉取地址为 https://github.com/bearaicn/BearaiProfessionMail.git。
- Gitee：额外远端 `gitee` 指向 https://gitee.com/bearaicn/BearaiProfessionMail.git。
- 本地 `origin` 配置两个 pushurl，分别为上述 GitHub 和 Gitee 地址；正常执行 `git push origin main`（或 main 上的 `git push`）会依次推送同一提交到两边。
- 推送完成后分别核对两边 main 与本地 HEAD 相同。双远端推送不具备跨服务原子性，一边失败时明确报告，并在解决后补推失败的一边，不强推。
- 新克隆不会继承本地的双 pushurl 和额外远端配置，需要重新设置。默认拉取仍从 GitHub，必要时单独 fetch gitee 核对。

## 两套客户端环境

`config/clients.json` 是部署目标配置：

| 部署目标 | 客户端目录 | 运行时数据 flavor | 当前 Interface | 最近观察版本 |
| --- | --- | --- | --- | --- |
| Hardcore | `_classic_era_` | era | 11509 | 1.15.9.70576 |
| Forever | `_forever_` | forever | 16001 | 1.60.1.70755 |

Hardcore 指经典旧世的部署目标；是否为硬核角色及具体规则由登录服务器决定。经典旧世普通服与硬核服目前共用 era 数据域，角色名称和服务器参与索引。

源码 TOC 声明两个 Interface，部署脚本按目标生成单一 Interface TOC。两套客户端安装目录、SavedVariables 以及游戏验收分别独立，代码来自同一个 Git 提交。规则遇到无限服专有内容时，后续按 flavor 加数据覆盖，不复制整个插件目录来维护。

## 四类版本

1. **插件版本**：以源码 TOC 的 `Version` 为唯一发布依据；`0.1.0` 表示当前功能迭代。修复加 patch、兼容功能加 minor、破坏性功能／数据变更评估 major。运行时通过客户端元数据接口读取 TOC 版本；package.json 是开发验证工具包版本。
2. **客户端版本和 Interface**：客户端版本是观察证据，Interface 是加载声明，二者与插件版本独立。客户端升级时重新核实配置；只改 Interface 不代表完成兼容。
3. **API 能力**：运行时检测 `C_Container`／旧背包 API、技能列表／专业 API 等，业务模块通过兼容接口处理。存在 API 不代表行为已通过游戏测试。
4. **数据版本**：SavedVariables 的 `schema=1`，仅在数据结构需要迁移时升级；未来升级必须提供迁移和回滚策略。插件补丁版本变化不自动提高 schema。

## 部署追踪和发布

每次发行必须更新 README.md 与 README.en.md 的“最新发行版与更新”、CHANGELOG.md 及 docs/releases/v版本号.md，再从干净提交创建新的附注标签 v版本号。已公开标签不移动、不覆盖；修复产生新版本标签。GitHub／Gitee 同步推送同一 Tag，Release 元数据与附件不随 Git 自动同步，需要分别创建。

发布打包：`scripts/Package.ps1` 从 TOC 和资源白名单生成两套最小 ZIP，包含 MIT LICENSE、安装说明及发布来源记录，输出到 .tmp/releases/v版本号；`scripts/Test-Packages.ps1` 验证目录、Interface、版本、源码哈希与 SHA256SUMS。干净提交是正式打包前提，-AllowDirty 仅供本地验证。未完成游戏验收时必须标注测试发行版／prerelease。

发行可按客户端分别验收和分发。当前 v0.3.2 已由用户确认经典旧世可用，正式发行目标仅为 Classic Era 1.15.9 / Interface 11509；无限服不因共享源码被视为已验证，本次不发布其安装附件。Package.ps1 与 Test-Packages.ps1 默认 Hardcore，可通过 -Client 指定其他目标；发布时只上传已验收目标的包与对应校验文件。公开 README 面向玩家，不包含本机绝对路径和开发过程。

用户随后明确要求同时分发无限服：两个平台同一发行版同时提供 era 已验证包与 forever-experimental 待验证包，说明按客户端标注状态。Package.ps1 支持 -Ref v版本号 从不可变标签导出构建，不要求切换当前分支；默认 Both。完整校验文件为 SHA256SUMS-ALL.txt，新增附件不覆盖原 era 包。旧版试打包附件仅标记已被取代，不擅自删除。

每次实际部署写入目标插件目录的 `deployment.json`，记录插件版本、目标 Interface、最近观察客户端版本、时间、Git 提交、工作区是否含未提交改动以及部署文件 SHA256。它是来源记录，不参与插件加载；`inGameValidation` 固定从 pending 开始，部署成功不等于游戏测试成功。

开发中可部署含未提交改动的版本用于调试，但正式发布应从干净提交产生。客户端分别记录测试状态，只通过经典旧世时不宣称无限服通过。首发标签为 `v0.3.2`，附件为 `BearaiProfessionMail-0.3.2-era.zip` 与 SHA256SUMS.txt；无限服验证后另行发行，不移动已公开标签。

客户端更新流程：只读检查路径和版本 → 更新 clients.json 与 TOC → 运行模拟测试及部署测试 → 指定客户端部署 → 游戏验收并记录实际 build 与结果。若 API 改动，只修改相关兼容实现和必要的数据，不从另一客户端的成功结果推断兼容。
