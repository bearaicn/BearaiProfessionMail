<p align="center">
  <img src="docs/assets/readme-hero.jpg" alt="BearAI Profession Mail" width="900">
</p>

<p align="center"><a href="README.md">简体中文</a> · <strong>English</strong></p>

# BearAI Profession Mail

**A World of Warcraft profession material mailing assistant with character management, material filtering, and native mailbox attachment controls.**

## Latest release: v0.5.6 (three-client preview)

| Client | Package | Validation |
| --- | --- | --- |
| Classic Era / Hardcore 1.15.9 / Interface 11509 | `BearaiProfessionMail-0.5.6-era.zip` | User verified 0.3.2; this build awaits in-game regression |
| Forever 1.60.1 / Interface 16001 | `BearaiProfessionMail-0.5.6-forever-experimental.zip` | Experimental; in-game verification pending |
| Classic Titan 3.80.2 / Interface 38002 | `BearaiProfessionMail-0.5.6-titan-experimental.zip` | User confirmed the stack right-click fix; new icon styling and full regression pending |

All packages share tag v0.5.6. Install the package for your client and check `SHA256SUMS-ALL.txt`. This is a prerelease; complete in-game verification is not claimed. Retail, Anniversary and other expansions are not targeted.

Changes since v0.3.2:

- Titan compatibility, separate client data profiles, and local profession material indexes generated from client-specific builds; sources are documented below.
- A separate item rule editor with item drops, user overrides and unmapped item maintenance; combined profession, game category and name / item ID filters.
- A mailbox entry that switches to the send tab, a 33-cell grid, profession-specific bulk attachment, and quantity selection with asynchronous split handling.
- Per-stack right-click attachment and removal; fixes for duplicate locked bag entries and incorrect removal of another stack. Attached icons keep their check mark and turn gray; removing restores color after unlocking.
- Item 6533 remains Fishing supplies only. Engineering outputs are not automatically Engineering reagents. Players still send mail themselves.

See the [changelog](CHANGELOG.md) and [release notes](docs/releases/v0.5.6.md). Fully restart the game when upgrading from an older build. Accounts and clients do not automatically share data.

## Installation

1. Download **`BearaiProfessionMail-0.3.2-era.zip` for Classic Era**. Optionally verify it against the release's `SHA256SUMS.txt`.
2. Extract the enclosed **`BearaiProfessionMail` folder** into the Classic Era client's `_classic_era_/Interface/AddOns/` directory.
3. Fully restart the game and enable the addon at character selection.

For Forever, use `BearaiProfessionMail-0.3.2-forever-experimental.zip` and install it under `_forever_/Interface/AddOns/`. It is experimental and has not passed in-game verification. Use `SHA256SUMS-ALL.txt` for both recommended packages. The earlier `forever.zip` was a preliminary build; prefer `forever-experimental.zip`.

Use the installation ZIP attached to the release. Automatically generated “Source code” archives are full repository snapshots, not the lightweight addon package.

## Usage

1. Opening the mailbox immediately shows **专业材料** (Profession Materials) left of its close button. Clicking selects the native second tab, Send Mail, and toggles the assistant. A switching failure gives a message without hiding the entry.
2. Select a character row. Search by character, realm, class, or profession, or add another character manually.
3. Materials are filtered by the target's professions by default. The dropdown also offers all mailable candidates, all materials, and individual professions. Item-name or item-ID search combines with filtering.
4. Switch to the native **Send Mail** tab. Right-click an unattached bag cell to add its stack; right-click a checked cell to remove its exact native attachment. Separate stacks of the same item do not remove each other. Double-click an unattached stack to choose a quantity, or drag it to a native attachment slot.
5. View and remove attachments in the native mailbox. The quantity dialog applies to the clicked bag stack only; it revalidates that slot and count before confirming. Partial quantities use the client's split-stack API and leave the remainder in the bag.
6. Verify the native recipient, attachments, and postage, then **click the native Send button yourself**.

Target selection can fill the recipient field; this option can be disabled. You may edit the field afterward, and material refreshes will not overwrite your changes. The filter target and native recipient are independent; always check the native recipient before sending.

The assistant can be expanded, collapsed, closed, and moved by dragging its header. Closing the mailbox hides it and its menus.

| Command | Action |
| --- | --- |
| `/bpm` | Toggle the assistant while the mailbox is open |
| `/bpm settings` | Open character management settings |
| `/bpm diag` | Show addon version, client version, and API details |

The settings page is also listed under **Settings → AddOns → 熊智专业邮寄助手 / BearAI Profession Mail**. It works without an open mailbox. Most interface labels are currently Simplified Chinese; this README is not a claim of complete English UI localization.

## Characters and account data

- Login records the current character's professions and level. Refresh updates only the logged-in character.
- Characters on the same WoW account and client flavor share records. Other characters update when you log in to them; the game saves on logout or `/reload`. This is not a live offline query.
- Different WoW accounts, including WoW1 and WoW2 on one Battle.net account, do not automatically share data. Era and Forever profiles are separate.
- A manual entry with exactly the same name and realm as a character you log in to becomes an automatic account record and is updated from game data.
- Manual records can be added, edited, and deleted. Automatic records update through login or refresh and cannot be manually overwritten.

## Material filters and rules

Open **Item Rules (物品规则)** from either the mail assistant or this addon's game settings page. It is a standalone window with a searchable, scrollable item list, an effective-source filter, and a separate editing area. It works without an open mailbox and does not share the character editor. The list merges assistant and user rules, regardless of current bag contents; it is not an encyclopedia of all game items.

Rows identify **Assistant data (助手数据)**, **User data (用户数据)**, or **User data overriding assistant data (用户数据（覆盖助手）)**. An item appears once. User assignments completely replace assistant assignments for that item; they are not merged. Editing any item saves to account/client SavedVariables without changing bundled files. Deleting its user rule restores assistant data if available, or removes a user-only item from the list. An empty saved profession selection is a user exclusion. Existing overrides remain compatible; normal logout or `/reload` writes them to disk.

The 0.4.0 development build also accepts a bag item dropped onto the item slot in the material-rule editor. Alternatively, pick up an item and left-click that slot. Its ID, icon, name and existing profession assignments are loaded automatically; select professions and save. The action reads the item identity and cancels the cursor pickup, leaving the item in the bag without attaching it to mail. Manual ID entry remains available. Uncached names refresh when the client returns item information. Three-client simulation passes; in-game verification is pending.

Includes the nine Classic primary professions plus Cooking, Fishing, and First Aid. One material can match multiple professions.

The 0.4.0 Titan build also includes Jewelcrafting and Inscription. Its expanded rules are isolated by client and do not enable these professions on other clients. Server-specific recipes may require additional item-ID rules.

| Filter | Behavior |
| --- | --- |
| Character professions — default | Match the selected character's recorded professions |
| All mailable items | Show candidates without locally known mailing restrictions |
| All materials | Use material categories, crafting-reagent flags, and known rules |
| Alchemy, Blacksmithing, etc. | Match the chosen profession independently of the target's professions |

Selecting a different character resets filtering to character professions and returns to page one. Search text is retained.

**物品规则** (Item Rules) supports multiple profession assignments. **删除用户规则 / 恢复助手数据** removes the user override and restores the assistant rule when present. Rules are shared within the same account and client flavor.

The 0.4.0 development build uses generated, client-specific material indexes, followed by maintainer supplements and player overrides. Search stays within the current filter: item names and IDs use literal substring matching, English is case-insensitive, and leading/trailing whitespace is ignored. Search never bypasses profession or mailing restrictions.

### Data sources, builds and updates

**Retrieved on November 4, 2026**, from Blizzard client DB2 records served by [wago.tools](https://wago.tools): `SkillLineAbility` links professions to spells; `SpellReagents` provides consumed items and quantities. Each dataset requests its own full client build. These are pinned available snapshots, not a promise of automatic coverage for future patches.

| Dataset | Client build / Interface | Profession/spell relations with reagents | Unique material IDs | Item/profession links |
| --- | --- | ---: | ---: | ---: |
| Classic Era / Hardcore | 1.15.9.70576 / 11509 | 1,570 | 501 | 853 |
| Classic Titan | 3.80.2.70522 / 38002 | 3,576 | 763 | 1,374 |
| WoW Forever | 1.60.1.70755 / 16001 | 2,494 | 589 | 1,084 |

Counts exclude curated supplements and spells without reagent consumption. A spell shared by multiple professions contributes one relation per profession. Ordinary realms share their client's dataset; actual ruleset differences belong in separate supplements.

The source repository retains raw CSVs, URLs, timestamps, SHA-256 hashes, normalized relations and per-profession counts: [source manifest](data-sources/manifest.json), [coverage](data-sources/coverage.json), [maintenance guide](data-sources/README.md). Installation packages contain only compact Lua indexes and required notices, excluding raw CSVs, normalized JSON and reference libraries. All three generated indexes together are about 44 KiB. No data downloads occur in game.

**Limits:** Client records may include unavailable or unreleased recipes; live server availability is not yet curated. Generic milling/prospecting inputs and non-recipe supplies use separate maintainer supplements. The index does not check learned recipes, skill levels or quantities needed, and is not an encyclopedia of every item. Gathering professions may have no consumption rules. Automated three-client simulation passes; this data/search update still requires in-game regression testing.

[LibCrafts-1.0](https://github.com/refaim/LibCrafts-1.0) and [LibProfessionDB](https://www.curseforge.com/wow/addons/libprofessiondb) were consulted as references, without embedding their code or databases. See [third-party notices](THIRD_PARTY_NOTICES.md). The project's MIT license does not grant rights in third-party game content.

Known bound and quest items are excluded, and locked items cannot be picked up. “Mailable” does not guarantee delivery to every recipient: realm, faction, and server restrictions remain subject to the native mailbox. Account-bound exceptions and partial-stack quantities are not supported.

## Feedback

Include client version, addon version, reproduction steps, and a Lua error or screenshot. `/bpm diag` helps confirm versions. Report issues through [GitHub Issues](https://github.com/bearaicn/BearaiProfessionMail/issues) or [Gitee Issues](https://gitee.com/bearaicn/BearaiProfessionMail/issues).

## License

[MIT License](LICENSE) · Copyright © 2026 BearAI (bearaicn). Use, modification, and distribution are permitted with copyright and license notices retained. The software is provided as is. Applicable game operator rules still apply.
