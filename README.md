# <4 (LT4)

**LT4** is a modular quality-of-life suite for World of Warcraft (Retail — Midnight 12.0.x). Built on the Ace3 framework, it provides a central hub for managing various UI and gameplay improvements.

## Modules

### Square Minimap
Transforms the circular minimap into a square design. Skins LibDBIcon addon buttons for a consistent flat look. Repositions built-in minimap elements (mail, tracking, queue status, zone text) to the corners. Zone text appears on hover only.

### LumiBar (Information Bar)
A full-width data bar anchored to the top or bottom of the screen. Modules are arranged via a drag-and-drop layout editor with five zones (Far Left, Near Left, Center, Near Right, Far Right).

**Sub-modules:**
- **Clock** — Clock display (12/24h), flashing colon, date, mail indicator, resting animation.
- **System** — FPS, latency, CPU, and memory usage.
- **Currency** — Gold display with colored denominations, expansion currencies, bag space.
- **Durability** — Equipment durability %, item level, color-coded warnings, repair mount summoning.
- **Travel** — Primary hearthstone with flyout for portals/teleports (auto-detects Mage spells), cooldown bars.
- **Profession** — Quick-access profession icons with skill progress bars.
- **Spec Switch** — Talent specialization and loadout switching.
- **Volume** — Master volume quick-control.
- **DataBar** — XP/reputation/honor progress bar with multiple display modes.
- **MicroMenu** — Compact row of game menu icons (character, spells, collections, etc.).

### Quality of Life
- **Tooltip IDs** — Adds Item, Spell, Currency, Achievement, Toy, and Mount IDs to all tooltips.
- **Better Fishing** — Double-right-click to cast your fishing rod. Optional sit-while-fishing.
- **Auto Repair** — Automatically repair gear at merchants (supports guild funds).
- **Auto Sell Junk** — Sells grey items automatically at merchants.
- **Collected Indicator** — Shows a checkmark and `[Known]` tag on already-collected items at merchants.

### Professions
- **Recipe Tracker Summary** — Toggleable consolidated view of tracked recipe reagents with inventory counts.
- **Skinning Rares Tracker** — Draggable UI panel tracking daily renowned beast completion status with clickable waypoints (supports TomTom). Chat command: `/skinning rares`.

---

## Installation

### Manual
1. Download the ZIP from the green **Code** button above.
2. Extract and move the folder into your AddOns directory:
   `World of Warcraft\_retail_\Interface\AddOns\`
3. Rename the folder from `LT4-main` to **`LT4`**.
4. `/reload` or restart the game.

### Git
```
cd "World of Warcraft\_retail_\Interface\AddOns"
git clone https://github.com/fubbleskag/LT4.git
```

## Updating

- **Manual:** Delete the `LT4` folder and re-download. Settings are stored in the WTF folder and will persist.
- **Git:** Run `git pull` from the `LT4` folder.

## Configuration

Type `/lt4` in chat or click the **<4** minimap icon / addon compartment button. Individual modules can be enabled or disabled from the main settings page, with per-module settings in sidebar sub-categories.
