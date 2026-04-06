# Project Context: LT4

A modular quality-of-life suite for World of Warcraft (Retail/Midnight), built on the Ace3 framework.

## Architecture & Standards
- **Core Module Management:** `Core.lua` acts as the central hub. It provides helpers like `RegisterModuleOptions`, `GetModuleEnabled`, and `SetModuleEnabled` to standardize module lifecycle and configuration.
- **Module Initialization:** 
  - Modules are defined using `LT4:NewModule`.
  - Use `OnInitialize` for registration (options, DB namespaces).
  - Use `OnEnable`/`OnDisable` to manage events, hooks, and UI elements.
- **Dynamic Configuration:** `LT4:RegisterModuleOptions` automatically adds a toggle to the main "Module Control" group and creates a dedicated sub-category in the Blizzard Options panel.
- **Sub-Feature Coordination:** Complex modules (like `Professions`) coordinate sub-files (like `Skinning.lua`) through explicit initialization hooks (e.g., `Module:InitSkinning()`) called during the parent module's `OnInitialize`.
- **Performance & Throttling:** UI updates, especially those tied to frequent events like `BAG_UPDATE` or `UNIT_AURA`, MUST be throttled using `C_Timer.After` to prevent performance spikes (see `LumiBar:UpdateZoneLayout` or `Professions:UpdateTracker`).

## Adding a New Module
1. **Create File:** Place in `Modules/<Category>/<Name>.lua`.
2. **Define Module:** `local Module = LT4:NewModule("<Name>", "AceEvent-3.0", ...)`
3. **Register:** Call `LT4:RegisterModuleOptions("<Name>", optionsTable)` in `OnInitialize`.
4. **Update TOC:** Add the file path to `LT4.toc` under the `# Modules` section.
5. **Handle State:** Use `if not LT4:GetModuleEnabled(self:GetName()) then self:SetEnabledState(false) end` in `OnInitialize` to respect the global toggle.

## LumiBar (Information Bar)
- **Modular Sub-system:** LumiBar has its own module registry (`LumiBar:RegisterModule`).
- **Zone Management:** Supports `Left`, `Center`, and `Right` zones for placing data modules.
- **Sub-Modules:** Located in `Modules/LumiBar/Modules/`. These follow a specific contract: `Init`, `Enable`, `Disable`, and optionally `Refresh`/`Update`.
- **Layout:** UI updates are throttled (0.05s) to ensure smooth transitions and avoid layout churn.

## ElvUI Skins
- **Integration:** Uses ElvUI's internal `Skins` module via `S:AddCallbackForAddon`.
- **Safety:** Always check `GetSkins()` and `C_AddOns.IsAddOnLoaded(addonName)` before applying skins.
- **Patterns:** Prefer `hooksecurefunc` for addons with dynamic UI (e.g., Auctionator, BugSack) to ensure skins are reapplied when frames are recreated or shown.

## External Dependencies
- **Ace3:** Heavily utilized for DB, Options, Events, and Hooks.
- **LibSharedMedia-3.0:** Used for fonts and textures.
- **LibDBIcon-1.0:** Manages the minimap icon and addon compartment integration.

## Media & Assets
- Custom textures and icons are stored in `Media/`.
- Icon paths in code typically follow: `Interface\AddOns\LT4\Media\<File>`.

## Development Roadmap (Upcoming)
- **Vendor Automation:** Auto-repair and auto-sell junk (grey items).
- **Minimap Enhancements:** Square shape, coordinate display, and zoom functionality.
- **UI Customization:** Ability to move and resize default Blizzard windows.
- **Safety Tools:** Auto-fill "DELETE" in confirmation dialogs.
