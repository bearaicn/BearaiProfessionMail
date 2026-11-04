<p align="center">
  <img src="docs/assets/readme-hero.jpg" alt="BearAI Profession Mail" width="900">
</p>

<p align="center"><a href="README.md">简体中文</a> · <strong>English</strong></p>

# BearAI Profession Mail

**A World of Warcraft profession material mailing assistant with character management, material filtering, and native mailbox attachment controls.**

## Supported game version

| Client | Status | Release package |
| --- | --- | --- |
| **Classic Era: 1.15.9, Interface 11509** | **User-reported in-game verification passed** | `BearaiProfessionMail-0.3.2-era.zip` |
| WoW: Forever | Compatibility work in progress; not verified in game | Not included in this release |

Classic Hardcore uses the same client family; realm-specific mailing rules still apply. This release does not target Retail, Anniversary, other Classic expansions, or untested future client versions.

## Latest release: v0.3.2

2026-11-04 · Classic Era release.

- Automatic character, class, level, and profession tracking, plus manual character management.
- Searchable character table, material filters, bag cells, and stack counts.
- Double-click to attach one stack, right-click to remove an attachment, and real bag-slot dragging. Sending remains manual.
- Selecting a different target resets filtering to its professions and returns to page one.
- Addon settings, bilingual branding, lightweight transparent logo, MIT License, installation ZIP, and SHA256 checksums.

Downloads: [GitHub Releases](https://github.com/bearaicn/BearaiProfessionMail/releases) · [Gitee Releases](https://gitee.com/bearaicn/BearaiProfessionMail/releases)

Full history: [CHANGELOG.md](CHANGELOG.md). Each release updates both READMEs and receives a new version tag.

## Installation

1. Download **`BearaiProfessionMail-0.3.2-era.zip` for Classic Era**. Optionally verify it against the release's `SHA256SUMS.txt`.
2. Extract the enclosed **`BearaiProfessionMail` folder** into the Classic Era client's `_classic_era_/Interface/AddOns/` directory.
3. Fully restart the game and enable the addon at character selection.

Use the installation ZIP attached to the release. Automatically generated “Source code” archives are full repository snapshots, not the lightweight addon package.

## Usage

1. Open the native mailbox and click **材料** (Materials) beside its bottom tabs, or below them when space is limited.
2. Select a character row. Search by character, realm, class, or profession, or add another character manually.
3. Materials are filtered by the target's professions by default. The dropdown also offers all mailable candidates, all materials, and individual professions. Item-name or item-ID search combines with filtering.
4. Switch to the native **Send Mail** tab. Double-click a bag cell to attach one stack, or drag it to an attachment slot.
5. Right-click a cell in the separate attachment row to return that stack to your bags. Right-clicking a bag item removes the last matching attachment with the same item link.
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

Includes the nine Classic primary professions plus Cooking, Fishing, and First Aid. One material can match multiple professions.

| Filter | Behavior |
| --- | --- |
| Character professions — default | Match the selected character's recorded professions |
| All mailable items | Show candidates without locally known mailing restrictions |
| All materials | Use material categories, crafting-reagent flags, and known rules |
| Alchemy, Blacksmithing, etc. | Match the chosen profession independently of the target's professions |

Selecting a different character resets filtering to character professions and returns to page one. Search text is retained.

**材料规则** (Material Rules) lets you override an item's profession assignments by item ID. Multiple professions are allowed; selecting none excludes it from profession matching. **恢复内置规则** restores the built-in rule. Rules are shared within the same account and client flavor.

The current mapping covers an initial set of common Classic materials. **It is not a complete recipe requirements database** and does not account for learned recipes, skill level, or quantities needed. Gathering professions may have no consumption rules, so an empty Herbalism or Skinning result can be expected.

Known bound and quest items are excluded, and locked items cannot be picked up. “Mailable” does not guarantee delivery to every recipient: realm, faction, and server restrictions remain subject to the native mailbox. Account-bound exceptions and partial-stack quantities are not supported.

## Feedback

Include client version, addon version, reproduction steps, and a Lua error or screenshot. `/bpm diag` helps confirm versions. Report issues through [GitHub Issues](https://github.com/bearaicn/BearaiProfessionMail/issues) or [Gitee Issues](https://gitee.com/bearaicn/BearaiProfessionMail/issues).

## License

[MIT License](LICENSE) · Copyright © 2026 BearAI (bearaicn). Use, modification, and distribution are permitted with copyright and license notices retained. The software is provided as is. Applicable game operator rules still apply.
