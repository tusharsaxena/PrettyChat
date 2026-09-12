# Ka0s Pretty Chat

![WoW](https://img.shields.io/badge/WoW-Midnight_12.1.0-purple)
![CurseForge Version](https://img.shields.io/curseforge/v/919766)
![License](https://img.shields.io/badge/License-MIT-orange)
![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)
![Tests](https://img.shields.io/badge/Tests-351%2F351_passing-green)

World of Warcraft tells you about loot, currency, gold, reputation, experience, honor and crafting in a stream of sentences that all look alike. PrettyChat rewrites them. Same information, laid out and color-coded, so the line you actually cared about is findable in a chat window that is scrolling past you.

Any message type can be switched off, reworded or recolored, either from the in-game settings panel or from chat with `/pc`.

## Screenshots

**_Without Pretty Chat_**

![Without Pretty Chat](https://media.forgecdn.net/attachments/1936/719/prettychat-screenshot-01-png.png)

**_With Pretty Chat_**

![With Pretty Chat](https://media.forgecdn.net/attachments/1936/720/prettychat-screenshot-02-png.png)

## Usage

The addon just works out of the box. On the first run after installing, there is no PrettyChat frame to place or size or lock, because your chat window is the display: the next thing you loot turns up already rewritten. Whichever frame you read chat in — the stock one, ElvUI's, Glass's — gets the tidy version.

Waiting on real loot is a poor way to judge a wording change, so you can ask for a sample instead. `/pc test` prints every message twice, the game's version above yours, and it does that even while the addon is switched off. Narrow it with `/pc test category Loot` or `/pc test formatstring LOOT_ITEM_SELF` when the full run is more than you wanted, or press **Test** on the **General** page to send that full run to the debug console instead of chat, which is a kinder place to read several hundred lines. Mid-edit you want neither: the settings panel carries the same before-and-after as a **Preview** box that updates while you type.

Editing happens on the **Categories** page. Pick a kind of message from the tabs across the top, then the individual line from the list down the left, and its editor opens beside it: the original wording, a box for yours, that live preview, an **Enable** checkbox and a **Reset**. Mind the `%s` and `%d` placeholders: they are the slots the item name and the amount get dropped into. You may stop short of the original's last one, and the line simply comes out without what it carried, but you cannot add a placeholder, change one's type or shuffle the order. PrettyChat refuses to save a version that does and prints both signatures, so the mistake that matters is hard to make. Colors are part of the wording rather than a separate control, so recoloring a line means editing its `|cffRRGGBB…|r` codes in the same box. All of this works from chat too, through `/pc set`, at the cost of doubling every `|` to `||`.

Three switches decide whether your version is used, checked in that order: the master **Enable PrettyChat**, then the category, then the message. Switch any one off and Blizzard's original comes back while your wording sits there waiting. The master lives on the **General** page with the **General visibility** dropdown beside it (*Always*, *Only in combat*, *Only out of combat*, *Never*), which is how you get PrettyChat during a fight and stock chat the rest of the time. Undo works at whatever scale you need: **Reset** on one message, **Defaults** on the tab you are looking at, **Reset all settings** for the lot. And if something is wrong rather than merely unwanted, `/pc debug` opens a session-only log window. Logging starts off, so `/pc debug on`, reproduce it, then **Copy** to lift the text into an issue.

Everything else is configuration, and it lives in two places: the addon's own page under Settings → AddOns in game, and `/pc` (or `/prettychat`), which prints the full command list.

## How it works

World of Warcraft builds each system message from a fixed template: a `%s` or a `%d` with some words around it. PrettyChat swaps in its own templates before the game reaches for them, so the line is already in your wording by the time any chat window sees it. That is the whole reason it needs no cooperation from the addon drawing that window.

The placeholder rule falls out of the same thing. Your template is handed the arguments the game's was, in the same order, and `string.format` cheerfully ignores an argument nobody asked for while raising on a conversion with nothing behind it. So a wording that stops short is safe, and four of PrettyChat's own shipped ones deliberately do stop short of Blizzard's last placeholder. A wording that asks for one more than the game passes is the one that would blow up inside Blizzard's chat handler, on every matching message, so the gate keeps only what it can vouch for: the conversions it does have must match the original's in type and order, and only the tail may go missing. That is why the check sits at the moment you save rather than in the preview: the write is refused, nothing is stored, and both signatures are printed so you can see where yours diverged.

Switching a message off does not throw your version away — it stops being applied, the original template goes back, and your wording is still there when you switch it on again. Settings are per account rather than per character, so one configuration covers every alt.

## FAQ

| Question | Answer |
|----------|--------|
| Does this work with ElvUI, Glass, or other chat addons? | Yes, with nothing to configure. PrettyChat changes the game's message templates before any chat window sees them, so whatever you use to display chat gets the tidy version automatically. |
| Why do some lines still look like the default? | Something's switched off. Check the master switch, the category, and that specific message. `/pc list category` shows them all in one place. A switched-off message always shows its original. |
| I edited a message and now it looks broken. | Your version is missing or misusing the `%s` / `%d` placeholders. Copy the original wording from the panel and edit around the placeholders, or turn the message off to restore it. |
| Can I change the colors? | Yes. The colors are part of the wording: each message's text carries WoW color codes (`\|cffRRGGBB…\|r`), so you recolor a line by editing those hex values right in its **New** box on the settings panel. There's no separate color picker. (Editing from chat works too, but you have to double every `\|` to `\|\|`.) |
| How do I preview my edits without waiting for real loot? | Two ways, and both work even while the addon is switched off. On the settings panel, each message has a live **Preview** that updates as you type. From chat, `/pc test` prints a before/after sample of every message — add a category (`/pc test category Loot`) or one string (`/pc test formatstring LOOT_ITEM_SELF`) to narrow it down. |
| Where are my settings saved? | They're shared across every character on your account — one configuration for all of them. Separate per-character or per-realm settings aren't available yet; if you'd like them, open an issue. |
| What's the **Debug console** for? Do I need it? | No. It's a troubleshooting aid for when you're filing a bug, nothing more. `/pc debug` (or the General-page toggle) opens a small on-screen log window. It starts empty because logging is off by default: turn it on with `/pc debug on` (or the window's own **Debug** switch), reproduce the problem, then use the window's **Copy** button to grab the text for your issue. Logging is session-only and resets every reload. |

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Nothing changed after installing | Make sure it's switched on: check the master switch, the category, and the message (`/pc get General.enabled` should be `true`). Then run `/pc test`. If the preview looks formatted but real chat doesn't, another addon is changing the same messages after PrettyChat. |
| A message I edited looks broken | Your wording dropped or misused a `%s` / `%d` placeholder. Restore the category with its **Defaults** button, or copy the original from the panel and edit around the placeholders. |
| The settings panel won't open | `/pc config` opens it from chat. Wait until you're fully loaded in, and note it won't open during combat. If the main page opens but a sub-page doesn't, click the sub-page's row in the settings list (**General** or **Categories**). |
| I want a clean slate | One message: its **Reset** button, or `/pc reset setting`. One category: open its tab and use the page's **Defaults** button, which acts on the tab you are looking at. Everything: `/pc resetall`, or **Reset all settings** on the General page. |
| I opened the debug console but it's empty | The window and logging are separate switches. Opening the window (`/pc debug`) doesn't start logging. Turn logging on first with `/pc debug on`, or the **Debug** toggle inside the window, then reproduce the problem. Use **Copy** to lift the log into a bug report. |
| I edited a crafting message and my change won't stick | A couple of strings (item and multi-item crafting results) live under both **Loot** and **Tradeskill**. They share one game template, so whichever of the two you edited last, after a `/reload` the **Tradeskill** version wins. Edit it in one place — the panel's Enable tooltip flags these shared strings. |

## Issues and feature requests

Found a bug or want a new feature? Everything is tracked on GitHub: [https://github.com/tusharsaxena/PrettyChat/issues](https://github.com/tusharsaxena/PrettyChat/issues). Please file it there rather than in a comment; that's where the project's to-do list actually lives.

## Version History

| Version | Date | Highlights |
|---------|------|------------|
| 1.5.0 | 2026-09-10 | The rewritten strings are now a searchable list beside the editor, with **Test** next to the reset<br>The eight category pages became eight tabs on one **Categories** page<br>The write seam now refuses a format string the game cannot serve, instead of failing at print time<br>Fixed three places that read a `nil` result as silence rather than as an answer<br>Updated for game patch 12.1.0 |
| 1.4.0 | 2026-07-12 | Added an on-screen debug console — `/pc debug`, or the new General-page **Debug console** toggle — a session-only log window for troubleshooting. Fixed the per-category **Defaults** button, and made a message's **Reset** restore its on/off state too. Updated for the current game patch. |
| 1.3.0 | 2026-05-03 | Rebuilt the settings panel: a page per category plus a General page (master Enable, Test, Reset All), a logo-and-commands landing page, and a cleaner layout for each message. Added the `/pc` commands (`help`, `list`, `get`, `set`, `reset`, `resetall`, `test`) so you can change any setting from chat, plus a `[PC]` tag on the addon's chat output. |
| 1.2.0 | 2026-04-24 | Added a searchable reference of the game's message strings to the settings panel. |
| 1.1.0 | 2026-02-14 | Made the game's message formats editable from the settings panel. |
| 1.0.0 | 2026-02-14 | Updated for WoW Midnight. |
| 0.0.3 | 2023-10-05 | Initial release. |
