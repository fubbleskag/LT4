# <4 (LT4)

**LT4** is a modular quality-of-life suite for World of Warcraft (Retail/Midnight), designed to provide a cohesive and lightweight set of tweaks and enhancements. Built on the Ace3 framework, it offers a central hub for managing various UI and gameplay improvements.

## Core Features

### 🛠️ Modular Architecture
Every feature in LT4 is a self-contained module. You can enable or disable exactly what you need through the main settings panel, keeping your UI clean and efficient.

### 📊 LumiBar (Information Bar)
A customizable data bar that provides at-a-glance information. LumiBar supports multiple zones (Left, Center, Right) and includes modules for:
*   **System:** FPS, Latency, and Memory usage.
*   **Currency:** Gold and specific expansion currencies.
*   **Durability:** Equipment status and repair costs. Includes customizable **Repair Mount** summoning (Left or Right click).
*   **Professions:** Quick access and tracking for your crafts with visual progress.
*   **Hearthstone:** Easy access to your primary teleport. Now includes auto-detection for **Mage Portals & Teleports**, plus **Cooldown & Progress Bars** in the flyout menus.
*   **Volume & Time:** Quick controls and clock display.

### 🛠️ Miscellaneous Tweaks
A collection of quality-of-life enhancements:
*   **Tooltip IDs:** Adds Item, Spell, Currency, Achievement, Toy, and Mount IDs to all tooltips globally.
*   **Better Fishing:** Double-right-click while not in combat to cast your fishing rod. Includes an optional "Sit while fishing" feature.

### 🌿 Professions & Gathering
Enhanced tools for the dedicated gatherer, including:
*   **Skinning Tracker:** Visual feedback and progress for skinning activities.
*   **General Tweaks:** Automation and UI improvements for various profession windows.

### 🎨 ElvUI Integration
Seamlessly blends your favorite addons with the ElvUI aesthetic. Includes custom skinning callbacks for popular addons to ensure a consistent look across your entire interface.

---

## Installation

### Method 1: Manual (Recommended for most users)
1.  **Download:** Click the green **Code** button at the top of this page and select **Download ZIP**.
2.  **Locate AddOns Folder:** Open your World of Warcraft installation directory, typically:  
    `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns`
3.  **Extract:** Open the ZIP file and move the `LT4-main` folder into the `AddOns` directory.
4.  **Rename:** Rename the folder from `LT4-main` to exactly **`LT4`**.
5.  **Restart:** Start the game or type `/reload` in chat if you are already logged in.

### Method 2: Git (Best for developers)
If you have Git installed, you can clone the repository directly into your AddOns folder to make updates effortless.
1.  Open a terminal (PowerShell or CMD) in your `AddOns` directory.
2.  Run the following command:
    ```powershell
    git clone https://github.com/fubbleskag/LT4.git
    ```

---

## Updating

### Manual Update
1.  Delete the existing `LT4` folder from your `AddOns` directory.
2.  Follow the **Manual Installation** steps above with the latest ZIP file.  
    *(Note: Your settings are stored in the WTF folder and will not be lost.)*

### Git Update
1.  Open a terminal in your `AddOns/LT4` folder.
2.  Run the following command:
    ```powershell
    git pull
    ```

---

## Configuration
Access the settings by typing `/lt4` in chat or by clicking the **<4** icon on your minimap/addon compartment.
