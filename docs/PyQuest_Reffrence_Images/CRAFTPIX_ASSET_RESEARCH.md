# PyQuest — CraftPix Asset Research

Status: research shortlist only. No asset archive has been downloaded or integrated into the app yet.

Purpose: improve PyQuest's visual quality without making it look like a preschool app. Prefer a modern learning product with a game-world layer: clear typography, restrained surfaces, useful whitespace, purposeful illustrations, and game assets used selectively.

## Priority shortlist

| Priority | Asset | Official page | Potential use | Caution |
|---|---|---|---|---|
| P0 | Free Kids Math Game UI Kit — Numbers & Counting | https://craftpix.net/ | Study quiz/question hierarchy, progress, feedback and level-completion patterns. Find the exact product from CraftPix search. | Use as a UX reference first; the theme may be too young for PyQuest's overall art direction. |
| P0 | Island Game – Free GUI | https://craftpix.net/freebies/island-game-gui/ | Study map, level-select, shop, score and pause layouts for the PyQuest village/Side Map. | Reuse only elements that fit the current product UI. |
| P0 | Free Jungle Cartoon 2D Game UI | https://craftpix.net/freebies/free-jungle-cartoon-2d-game-ui/ | Study complete UI states: home, settings, levels, rating, shop, success/failure, pause and dialogs. | Bright cartoon style can become visually noisy; do not copy the full theme blindly. |
| P1 | Kids Fantasy Game – Free GUI | https://craftpix.net/freebies/kids-fantasy-game-gui/ | Compare skill, shop, options and level-completion screen structures. | Treat as a component reference, not the target look. |
| P1 | Free Market Cartoon 2D Game Tileset | https://craftpix.net/freebies/free-market-cartoon-2d-game-tileset/ | Explore village/shop buildings, environment props and a coherent Side Map scene. | Confirm actual archive contents and scale before integration. |
| P1 | Free Island Adventure Pixel Top-Down Minigame Kit | https://craftpix.net/all-game-assets/ | Explore an optional map/adventure layer and its world-building assets. | Pixel art may clash with a clean vector UI; use only if a deliberate pixel-art direction is chosen. |
| P1 | Free Medieval Fortress Top-Down Pixel Minigame Kit | https://craftpix.net/all-game-assets/ | Explore landmarks, map progression and world locations. | Same pixel-art consistency warning. |
| P2 | Free Buttons 2D Game Objects | https://craftpix.net/freebies/free-buttons-2d-game-objects/ | Inspect button shapes and states as implementation reference. | Do not mix button styles from several kits in one screen. |
| P2 | Free Horizontal 2D Game Backgrounds | https://craftpix.net/freebies/free-horizontal-2d-game-backgrounds/ | Potential background layers for a game-mode scene or promotional screen. | Not a default background for code editor, lessons, or chat; keep text readable. |

CraftPix's free catalog: https://craftpix.net/freebies/  
All assets: https://craftpix.net/all-game-assets/  
GUI category: https://craftpix.net/categorys/gui/  
Cartoon GUI category: https://craftpix.net/categorys/cartoon-gui/

## Map assets to PyQuest features

- **Home / learning dashboard:** borrow layout principles (content hierarchy, cards, progress, clear primary action), not a full game HUD.
- **Lesson and Python editor:** keep a calm, high-contrast, productivity-oriented interface. Avoid decorative backgrounds behind code.
- **Arena modes / Creator Pro League:** use consistent mode icons, badges and compact status indicators; keep labels readable and accessible.
- **PyQuest village / Side Map:** strongest candidate for environment art, landmarks, paths and location markers.
- **Rewards / titles / leaderboard:** select one coherent icon or badge family; do not combine unrelated packs.
- **AI Tutor:** preserve a conversational layout and legible transcript; avoid game HUD framing around every message.

## Download and integration workflow

1. Open the official product page and download only when the page explicitly offers a free download.
2. Inspect the archive and preview before choosing it. Prefer transparent PNGs or vector source files that can be exported cleanly for Flutter.
3. Record the exact product title, source URL, download date, license URL, and any attribution requirement in an asset manifest.
4. Keep original archives outside the runtime asset bundle unless the app actually needs them. Copy only selected, optimized files into the app's asset directory.
5. Check image dimensions, transparency, file size, Android rendering, dark/light surfaces, and small-screen scaling.
6. Do not commit premium-only downloads, scraped preview images, fonts, or files whose license cannot be verified.
7. Before release, verify the current license for each exact item. CraftPix product pages may differ; a general site statement is not a substitute for the exact item's terms.

## Selection gate

An asset is accepted only if it:
- makes a real screen clearer or more engaging;
- fits the chosen PyQuest visual direction rather than making the whole app look like a preschool game;
- is technically usable in Flutter at phone scale;
- has a verified source and license;
- is optimized and does not unnecessarily inflate the APK.

## Important status

This document is a shortlist for investigation, not evidence that the assets have been downloaded, license-reviewed, or integrated. Update this file with the exact products and manifest entries only after inspecting the actual archives.
