<p align="center">
  <img src="docs/assets/readme-hero.jpg" alt="BearAI Profession Mail / 熊智专业邮寄助手" width="900">
</p>

<p align="center"><a href="README.md">简体中文</a> · <strong>English</strong></p>

# BearaiProfessionMail

**A World of Warcraft profession material mailing assistant with character management, material filtering, and native mailbox attachment controls.**

Version **0.3.2**. Shared Lua business logic with runtime capability detection for Classic Era and WoW: Forever.

Current status: character management, inventory scanning, profession matching, and real bag-slot interactions are implemented. Local syntax checks and mocked behavior tests pass. **In-game acceptance testing is not complete.**

## Usage

1. Log in to each character on your WoW account to record its name, realm, class, level, and professions. Records are shared within the same WoW account and client flavor; level-up events update the current character.
2. Open the native mailbox and click **材料** (Materials) beside its bottom tabs. If there is insufficient room, the button appears below the tabs. Click again or close the assistant to collapse it. Closing the mailbox also closes the assistant and its menus.
3. Click a row in the character table to select a recipient. Search by character, realm, class, or profession; scroll with the mouse wheel or arrow buttons. The table displays class, level, and professions, with realm and record source below the name. Add characters from other accounts manually; class and level are optional. Missing fields in older records display as unknown. Manual records can be edited or deleted with confirmation; automatically recorded characters cannot be manually overwritten.
4. By default, selecting a different target fills the native recipient field. This option can be disabled. You may edit the recipient afterward; refreshing materials will not overwrite your edits.
5. Switch to the native **Send Mail** tab. Double-click a bag cell to attach one stack, or drag it to a native attachment slot. The separate attachment row always shows the current native attachments. Right-click an attachment to return that stack to your bags. Right-clicking a bag item removes the last matching attachment with the same item link. Each cell retains its real bag slot or attachment index; identical stacks are not merged. The bag area has 22 cells and supports paging with buttons or the mouse wheel.
6. Check the native recipient, attachments, and postage, then click the native **Send** button yourself.

The selected character determines filtering. Editing the native recipient does not change the filter target. Always use the native recipient field as the final destination check. Realm, faction, Hardcore, and attachment restrictions are enforced by the game.

Commands:

| Command | Action |
| --- | --- |
| `/bpm` | Toggle the assistant while the mailbox is open |
| `/bpm diag` | Show addon version, client build, Interface, and API capabilities |
| `/bpm settings` | Open the addon settings page |

You can also find **熊智专业邮寄助手 / BearAI Profession Mail** under the game's Settings → AddOns. The settings page supports searching, adding, editing, and deleting manual records, and refreshing the current character without opening a mailbox. Selecting a character in settings does not fill the native recipient field. The interface currently uses Simplified Chinese labels; this English README does not imply full English UI localization.

### Account data boundaries

SavedVariables are shared by characters on the same WoW account and client flavor. The addon reads only the currently logged-in character. Other characters update when you log in to them; the game saves data on logout or `/reload`, and subsequent character sessions read it. This is not an offline or live cross-character query.

Different WoW accounts, including WoW1 and WoW2 on the same Battle.net account, do not automatically share data. Classic Era and Forever are separate. A manual record with exactly the same character name and realm as a character you log in to is replaced with observed class, level, and profession information and becomes an automatic account record. A different realm spelling will not be merged automatically.

## Professions and materials

The addon includes the nine Classic primary professions plus Cooking, Fishing, and First Aid. Multiple professions are supported. Gathering professions do not automatically request everything they produce: ore is matched to Mining, fish mainly to Cooking or Alchemy, and fishing bait to Fishing. Herbalism and Skinning may have no matching consumption rules.

`Data/ProfessionMaterials.lua` contains an initial item-ID-to-profession mapping for common Classic materials. It is not a complete recipe database and does not account for skill level, learned recipes, or required quantities. Forever-specific materials are not yet covered. Search by item name or ID, filter by profession, page through results, and inspect real bag tooltips. Known bound items are hidden; locked items remain visible but cannot be picked up.

Use **材料规则** (Material Rules) to enter an item ID and select its professions. A custom rule replaces the built-in assignment for that item. Multiple professions are allowed; selecting none explicitly excludes the item from profession matching. **恢复内置规则** (Restore Built-in Rule) removes the override. Rules are shared within the same account and client flavor.

### Filters

| Mode | Behavior |
| --- | --- |
| By character professions — default | Match the selected character's recorded professions |
| All mailable items | Show candidates without locally known mailing restrictions |
| All materials | Use trade-goods/reagent categories, crafting-reagent flags, and known rules |
| An individual profession | Match that profession regardless of the selected character's professions |

Selecting a different character always resets the filter to **By character professions** and returns to page one. Search text is retained and combines with the chosen filter. All Materials can include materials without a profession rule.

All Mailable Items is a candidate list, not a guarantee: bound and quest items are excluded, while recipient-specific, cross-realm, account-bound, and server rules remain subject to the native mailbox. Account-bound items are not specially enabled in this version.

Double-click and right-click operations affect one stack in the draft being edited. They do not send mail or perform bulk actions. Full attachments, combat, an occupied cursor, locked items, pending mail operations, and stale attachment identities are guarded. If the native mailbox rejects an attachment and the item remains on your cursor, return it to a bag or place it manually; the addon does not clear the cursor automatically.

## Development and deployment

Local client observations from **2026-11-04**:

| Target | Local directory | Executable version | TOC Interface |
| --- | --- | --- | --- |
| Classic Era / Hardcore testing | `D:\Games\World of Warcraft\_classic_era_` | 1.15.9.70576 | 11509 |
| WoW: Forever | `D:\Games\World of Warcraft\_forever_` | 1.60.1.70755 | 16001 |

Versions were checked against local `.build.info` and executables; Interface values were cross-checked with installed addon declarations. An installation directory does not establish whether a character is on a Hardcore realm. Recheck after a client update and use `/bpm diag` in game.

Run PowerShell from the project root:

```powershell
# Inspect client paths and versions
.\scripts\Inspect-Clients.ps1
# Preview both targets; no files are copied without -Apply
.\scripts\Deploy.ps1 -Client Both
# Deploy to Classic Era
.\scripts\Deploy.ps1 -Client Hardcore -Apply
# Deploy to Forever
.\scripts\Deploy.ps1 -Client Forever -Apply
# Use -GameRoot to specify another installation root
```

Deployment reads `config/clients.json`, generates a target-specific Interface declaration, and copies the Lua files listed in the TOC plus resources listed in `config/assets.json`. SHA256 hashes are verified. `deployment.json` records addon version, Git source, working-tree state, and file hashes. The current installation contains 18 addon files plus this provenance record.

The script does not delete destination files or modify other addons or WTF/SavedVariables. It overwrites matching files belonging to this addon; preserve any older build you need. Roll back the source with Git and redeploy when appropriate. Fully restart after initial installation, new modules, or unrecognized textures; updates to existing Lua files can use `/reload`.

The approved bear-and-envelope logo is resized to 128×128. `Media/logo-bear-mail-v1.png` is the transparent PNG reference (28,040 bytes); `Media/Logo.tga` is the 32-bit transparent game texture (65,554 bytes). Only the TGA is deployed. PNG references, README banners, original large images, and development files are excluded. `scripts/Prepare-Logo.ps1 -Source ...` rebuilds the PNG and TGA using resampling and format conversion.

Git uses a shared `main` branch with separate client configuration, deployment, and acceptance testing. Addon version comes from the TOC; client Interface and SavedVariables schema are independent. See [Versioning strategy — Chinese](docs/VERSIONING.md).

```powershell
npm ci --ignore-scripts --registry=https://registry.npmjs.org
npm test
.\scripts\Test-Deployment.ps1
```

Node is used only for development checks. The game does not require Node, and deployment excludes node_modules and test code. Lua 5.1 syntax is checked with luaparse; behavior runs in Fengari with mocked WoW APIs. These checks cannot prove real protected-operation behavior, visual layout, or server rules.

## Data and modules

`BearaiProfessionMailDB` is account-wide SavedVariables with `schema=1 / profiles[era|forever] / characters,rules,settings`. Client profiles are isolated. Professions use stable skill-line IDs; characters use name-realm keys. Login, profession-change, and level-up handling update the current character. The game persists data on logout or reload. Unsupported future schemas are rejected to prevent older addon versions from overwriting newer data.

Core handles initialization, storage, and compatibility. Modules handle characters, professions, inventory, matching, and mail. `UI/Theme.lua` and `UI/Widgets.lua` provide an independent dark theme without requiring RurutiaSuite or another skin. The assistant prefers the right side of the mailbox, tries the left when necessary, and falls back within the screen. Its header can be dragged.

Frames are created in Lua; no extra XML is required. Profession detection supports the skill list, including restoring collapsed headers, and sparse `GetProfessions` results. Bags support `C_Container` and legacy globals. Only carried bags 0–4 are scanned, not banks or other characters' inventory. Optional class and level fields remain compatible with schema 1.

API references: [Container documentation](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua), [native mail implementation](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_UIPanels_Game/Classic/MailFrame.lua), and [Classic skill panel](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_UIPanels_Game/Classic/SkillFrame.lua). These upstream references may change and do not replace acceptance tests on the actual client.

Further project records: [Development progress — Chinese](docs/PROGRESS.md), [Test checklist — Chinese](docs/TESTING.md), and [structured progress](docs/progress.json).
