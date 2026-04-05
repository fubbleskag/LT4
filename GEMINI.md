# Project Context: LT4

A modular quality-of-life suite for World of Warcraft (Retail/Midnight).

## Architecture & Standards
- **Core Module Management:** `Core.lua` provides centralized helpers (`RegisterModuleOptions`, `GetModuleEnabled`, `SetModuleEnabled`) to reduce boilerplate in individual modules.
- **Module Initialization:** Modules use `OnInitialize` to register options and `OnEnable`/`OnDisable` to manage events and hooks.
- **Sub-Feature Coordination:** Complex modules (like `Professions`) coordinate sub-files (like `Skinning.lua`) through explicit initialization hooks (e.g., `Module:InitSkinning()`) instead of monkey-patching.
- **Performance:** UI updates (especially in the Objective Tracker) are throttled using `C_Timer.After` to prevent event-driven performance spikes.

## Module Notes
### ElvUI Skins
- Provides data-driven skinning for third-party addons (Auctionator, BugSack, MacroToolkit, PGF).
- **Auctionator:** Specifically handles dynamic bottom tabs via `AuctionatorTabContainerMixin`.

### Professions Module
- **Summary View:** Provides a consolidated view of reagents for all tracked recipes.
- **Skinning:** Includes a "Renowned Beasts" daily rare tracker that integrates with TomTom or the native waypoint system.
- **Skinning Tracker:** Supports a standalone UI or integration with `MyusKnowledgePointsTracker` (MKPT).
