# Ka0s Pretty Chat

![WoW](https://img.shields.io/badge/WoW-Midnight_12.1.0-purple)
![CurseForge Version](https://img.shields.io/curseforge/v/919766)
![License](https://img.shields.io/badge/License-MIT-orange)
![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)
![Tests](https://img.shields.io/badge/Tests-518%2F518_passing-green)

World of Warcraft tells you about loot, currency, gold, reputation, experience, honor and crafting in a stream of sentences that all look alike. PrettyChat rewrites them. The information doesn't change, but it's laid out and color-coded, so you can find the line you actually cared about while the chat window scrolls past you.

You can switch off, reword or recolor any message type, either in the in-game settings panel or from chat with `/pc`.

## Screenshots

**_Without Pretty Chat_**

![Without Pretty Chat](https://media.forgecdn.net/attachments/1936/719/prettychat-screenshot-01-png.png)

**_With Pretty Chat_**

![With Pretty Chat](https://media.forgecdn.net/attachments/1936/720/prettychat-screenshot-02-png.png)

## Usage

Install it and it works. There's no PrettyChat frame to place, size or lock on the first run, because your chat window is the display. The next thing you loot turns up already rewritten, in whichever frame you read chat in: the stock one, ElvUI's or Glass's.

Waiting for real loot is a poor way to judge a wording change, so you can ask for a sample instead. `/pc test` writes every message twice to the debug console, with the game's version above yours, which keeps several hundred lines out of your chat window. The **Test** button on the **General** page does the same run. If the full run is more than you wanted, narrow it with `/pc test category Loot` or `/pc test formatstring LOOT_ITEM_SELF`. There's one difference while the addon is switched off: the button still works, but `/pc test` just tells you to `/pc enable` first. While you're in the middle of an edit you need neither, because the settings panel shows the same before-and-after in a **Preview** box that updates as you type.

You edit messages on the **Categories** page. Pick a kind of message from the tabs across the top and then a line from the list down the left, and its editor opens beside the list. It has the original wording, a box for yours, that live preview, an **Enable** checkbox and a **Reset** button.

Watch the `%s` and `%d` placeholders. They are the slots the game drops the item name and the amount into. You're allowed to stop before the original's last one, and the line simply comes out without whatever it carried. What you can't do is add a placeholder, change one's type or shuffle the order. PrettyChat refuses to save a version that does any of that and prints both signatures, so the mistake that matters is hard to make. Colors are part of the wording, not a separate control: to recolor a line, you edit its `|cffRRGGBB…|r` codes in the same box. All of this works from chat too, through `/pc set`, but there you have to double every `|` to `||`.

Three switches decide whether your version is used, checked in this order: the master **Enable PrettyChat**, then the category, then the message. Turn any one of them off and Blizzard's original comes back, while your wording stays saved. The master switch also works from chat, where `/pc disable` turns PrettyChat off and `/pc enable` turns it back on. On the **General** page it sits next to the **General visibility** dropdown (*Always*, *Only in combat*, *Only out of combat*, *Never*). That dropdown is how you get PrettyChat during a fight and stock chat the rest of the time.

Undo goes as far back as you need. **Reset** undoes one message. **Defaults** on the Categories page resets every category tab at once. **Reset all settings** resets the lot, and so does the General page's own **Defaults** button, which is the same reset.

PrettyChat also puts a button with its logo on your minimap. Left-click it to open the settings. Right-click it for a small menu with an **Enabled** tick box, which switches PrettyChat off and on (it's the same switch as `/pc disable` and `/pc enable`). Hover over it to see the version and whether PrettyChat is on. If you'd rather not have the button, clear the **Minimap button** checkbox on the **General** page. If you run Titan Panel, Bazooka or ElvUI's data texts, the same button shows up there too.

If something is actually broken rather than just not to your taste, `/pc debug` opens a session-only log window. [Reporting a bug](#reporting-a-bug) below says what to do with it.

Everything else is configuration, and there are two ways in: the addon's own page under Settings → AddOns in game, and `/pc` (or `/prettychat`), which opens that same page. `/pc help` prints the full command list, and `/pc version` prints the version you're running.

## How it works

World of Warcraft builds each system message from a fixed template, which is a `%s` or a `%d` with some words around it. PrettyChat swaps in its own templates before the game reaches for them, so the line is already in your wording by the time any chat window sees it. That's why it needs no cooperation from whatever addon draws the window.

The placeholder rule comes from the same mechanism. Your template is handed the same arguments the game's template gets, in the same order. `string.format` cheerfully ignores an argument nobody asked for, but it raises an error on a conversion with nothing behind it. So a wording that stops short is safe, and four of PrettyChat's own shipped wordings deliberately stop short of Blizzard's last placeholder. A wording that asks for one more than the game passes would blow up inside Blizzard's chat handler, on every matching message. The gate therefore keeps only what it can vouch for: the conversions your wording does have must match the original's in type and order, and only the tail may go missing. This is also why the check happens when you save and not in the preview. PrettyChat refuses the write, stores nothing, and prints both signatures so you can see where yours differs.

Switching a message off doesn't throw your version away. PrettyChat stops applying it and puts the original template back, and your wording is still there when you switch the message on again. Settings are per account, not per character, so one configuration covers every alt.

## FAQ

| Question | Answer |
|----------|--------|
| Does this work with ElvUI, Glass, or other chat addons? | Yes, and there's nothing to configure. PrettyChat changes the game's message templates before any chat window sees them, so whatever you use to display chat gets the tidy version automatically. |
| Why do some lines still look like the default? | Something's switched off. Check the master switch, the category, and that specific message. `/pc list category` shows them all in one place. A switched-off message always shows its original. |
| I edited a message and now it looks broken. | Your version is missing or misusing the `%s` / `%d` placeholders. Copy the original wording from the panel and edit around the placeholders, or turn the message off to restore it. |
| Can I change the colors? | Yes. The colors are part of the wording. Each message's text carries WoW color codes (`\|cffRRGGBB…\|r`), so you recolor a line by editing those hex values in its **New** box on the settings panel. There's no separate color picker. (Editing from chat works too, but you have to double every `\|` to `\|\|`.) |
| How do I preview my edits without waiting for real loot? | There are two ways. On the settings panel, each message has a live **Preview** that updates as you type. From chat, `/pc test` writes a before/after sample of every message to the debug console. Add a category (`/pc test category Loot`) or one string (`/pc test formatstring LOOT_ITEM_SELF`) to narrow it down. While the addon is switched off, `/pc test` asks you to turn it back on, but the Preview and the General page's **Test** button keep working. |
| Where are my settings saved? | They're shared by every character on your account, so one configuration covers all of them. Separate per-character or per-realm settings aren't available yet. If you'd like them, open an issue. |
| What's the **Debug console** for? Do I need it? | No. It's there to help when you're filing a bug, nothing more. `/pc debug` (or the General-page toggle) opens a small on-screen log window. It starts empty because logging is off by default, and [Reporting a bug](#reporting-a-bug) says how to turn it on and copy out what it caught. Logging is session-only and resets on every reload. |

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Nothing changed after installing | Make sure it's switched on by checking the master switch, the category, and the message (`/pc get General.enabled` should be `true`). Then run `/pc test`. If the preview looks formatted but real chat doesn't, another addon is changing the same messages after PrettyChat. |
| A message I edited looks broken | Your wording dropped or misused a `%s` / `%d` placeholder. Restore that one message with its **Reset** button (or `/pc reset path`), or copy the original from the panel and edit around the placeholders. The Categories page's **Defaults** button also fixes it, but it resets every category tab, so you lose your edits in the other categories too. |
| The settings panel won't open | `/pc config` opens it from chat. Wait until you're fully loaded in, and note that it won't open during combat. If the main page opens but a sub-page doesn't, click the sub-page's row in the settings list (**General** or **Categories**). |
| I want a clean slate | For one message, use its **Reset** button or `/pc reset path` (`/pc list` shows the paths). For every category's strings, use the Categories page's **Defaults** button, which resets every category tab and not only the one you're looking at. For everything, use `/pc resetall`, **Reset all settings**, or the **Defaults** button on the General page (both buttons ask first). |
| I opened the debug console but it's empty | The window and logging are separate switches, and opening the window (`/pc debug`) doesn't start logging. Turn logging on first with `/pc debug on` or the **Debug** toggle inside the window, then reproduce the problem. To send it in, follow [Reporting a bug](#reporting-a-bug) below. |
| The "you create an item" messages are gone from the Loot tab | They're on the **Tradeskill** tab now, and only there. They used to appear on both tabs, but only the Tradeskill copy ever reached chat. If you had customized the Loot copy, your wording moved to the Tradeskill tab the first time you logged in on this version. |
| Something looks wrong and I want to report it | Follow [Reporting a bug](#reporting-a-bug) below. |

## Reporting a bug

1. Type `/pc debug on` and reproduce the bug.
2. Type `/pc diagnostics`.
3. If the debug window isn't open, open it with `/pc debug`. Press **Copy**, copy the entire output, and include it with your bug report.

The report is added after the debug trace in the same window, so one copy carries both.

## Issues and feature requests

Bugs and feature requests are tracked on GitHub: [https://github.com/tusharsaxena/PrettyChat/issues](https://github.com/tusharsaxena/PrettyChat/issues). Please file them there rather than in a comment, because that's where the project's to-do list actually lives.

## Version History

| Version | Date | Highlights |
|---------|------|------------|
| 1.5.0 | 2026-09-10 | - The rewritten strings are now a searchable list beside the editor, with **Test** next to the reset<br>- The eight category pages became eight tabs on one **Categories** page<br>- A format with a placeholder the game cannot fill is now refused when you save it, instead of failing when the message prints<br>- Updated for game patch 12.1.0 |
| 1.4.0 | 2026-07-12 | - Added an on-screen debug console (`/pc debug`, or the new General-page **Debug console** toggle), a session-only log window for troubleshooting. Fixed the per-category **Defaults** button, and made a message's **Reset** restore its on/off state too. Updated for the current game patch. |
| 1.3.0 | 2026-05-03 | - Rebuilt the settings panel: a page per category plus a General page (master Enable, Test, Reset All), a logo-and-commands landing page, and a cleaner layout for each message. Added the `/pc` commands (`help`, `list`, `get`, `set`, `reset`, `resetall`, `test`) so you can change any setting from chat, plus a `[PC]` tag on the addon's chat output. |
| 1.2.0 | 2026-04-24 | - Added a searchable reference of the game's message strings to the settings panel. |
| 1.1.0 | 2026-02-14 | - Made the game's message formats editable from the settings panel. |
| 1.0.0 | 2026-02-14 | - Updated for WoW Midnight. |
| 0.0.3 | 2023-10-05 | - Initial release. |

## Credits

The debug console uses [JetBrains Mono](https://www.jetbrains.com/lp/mono/), licensed under the SIL
Open Font License 1.1. It ships inside the bundled LibKa0s payload, with its license text beside it.
