# PyQuest — CraftPix Asset Research

Status: curated shortlist. Asset archives have not yet been downloaded or integrated into the app.

Purpose: improve PyQuest's visual quality without making it look like a preschool app. Prefer a modern learning product with a game-world layer: clear typography, restrained surfaces, useful whitespace, purposeful illustrations, and game assets used selectively.

## Priority shortlist

| Priority | Asset | Official product page | Potential use | Caution |
|---|---|---|---|---|
| P0 | Free Kids Math Game UI Kit — Numbers & Counting | https://craftpix.net/freebies/free-kids-math-game-ui-kit-numbers-counting/ | Study quiz hierarchy, progress, correct/incorrect feedback, badges and rewards. It includes separate vector assets and five mini-game templates. | Explicitly designed for young children; use only selected components as references, not the whole visual style. |
| P0 | Island Game – Free GUI | https://craftpix.net/freebies/island-game-gui/ | Study map, level select, shop, high-score and pause layouts; candidate for PyQuest Village / Side Map. | Select only pieces that fit the product's visual system. |
| P0 | Free Jungle Cartoon 2D Game UI | https://craftpix.net/freebies/free-jungle-cartoon-2d-game-ui/ | Study complete UI states: home, settings, levels, rating, shop, success/failure, pause and dialogs. Includes AI/EPS and PNG. | Colorful cartoon theme can become noisy; don't copy the entire skin. |
| P1 | Kids Fantasy Game – Free GUI | https://craftpix.net/freebies/kids-fantasy-game-gui/ | Compare skills, shop/options and level-completion screen structures. | Component reference only; avoid a preschool aesthetic. |
| P1 | Free Market Cartoon 2D Game Tileset | https://craftpix.net/freebies/free-market-cartoon-2d-game-tileset/ | Explore village/shop buildings, environment props and a coherent Side Map scene. | Confirm archive contents, style and scale before integration. |
| P1 | Free Island Adventure Pixel Top-Down Minigame Kit | https://craftpix.net/freebies/free-island-adventure-pixel-top-down-minigame-kit/ | Explore an optional map/adventure layer and world-building assets. | Pixel art may clash with a clean vector UI; use only if pixel art is chosen deliberately. |
| P1 | Free Medieval Fortress Top-Down Pixel Minigame Kit | https://craftpix.net/freebies/free-medieval-fortress-top-down-pixel-minigame-kit/ | Explore landmarks, map progression and world locations. | Same pixel-art consistency warning. |
| P2 | Free Buttons 2D Game Objects | https://craftpix.net/freebies/free-buttons-2d-game-objects/ | Inspect button shapes and states as implementation reference. | Don't mix unrelated button styles from multiple packs in one screen. |
| P2 | Free Horizontal 2D Game Backgrounds | https://craftpix.net/freebies/free-horizontal-2d-game-backgrounds/ | Potential background layers for a game-mode scene or promotional screen. | Not a default background for the code editor, lessons or AI Tutor; preserve text/code contrast. |
| P2 | Free Alphabet Vector Asset Kit for Education Games | https://craftpix.net/freebies/free-alphabet-vector-asset-kit-for-education-games/ | Inspect reusable education-related symbols and letter assets if a lesson actually needs them. | Avoid adding decorative alphabet art to Python screens without a clear purpose. |

CraftPix's free catalog: https://craftpix.net/freebies/  
All assets: https://craftpix.net/all-game-assets/  
GUI category: https://craftpix.net/categorys/gui/  
Cartoon GUI category: https://craftpix.net/categorys/cartoon-gui/  
Official license terms: https://craftpix.net/file-licenses/

## Map assets to PyQuest features

- **Home / learning dashboard:** borrow layout principles (content hierarchy, cards, progress, clear primary action), not a full game HUD.
- **Lesson and Python editor:** keep a calm, high-contrast, productivity-oriented interface. Avoid decorative backgrounds behind code.
- **Arena modes / Creator Pro League:** use consistent mode icons, badges and compact status indicators; keep labels readable and accessible.
- **PyQuest village / Side Map:** strongest candidate for environment art, landmarks, paths and location markers.
- **Rewards / titles / leaderboard:** select one coherent icon or badge family; do not combine unrelated packs.
- **AI Tutor:** preserve a conversational layout and legible transcript; avoid game HUD framing around every message.

## Download and integration workflow

1. Open each official product page and use the site's own free-download flow; confirm it is marked free rather than premium-only.
2. Inspect the downloaded archive locally. Prefer transparent PNGs or vector files that can be exported cleanly for Flutter.
3. Record the exact product title, source URL, download date, license URL, and attribution requirements in an asset manifest.
4. Keep original archives outside the runtime asset bundle unless the app actually needs them. Copy only selected, optimized files into the app's asset directory.
5. Check image dimensions, transparency, file size, Android rendering, dark/light surfaces, and small-screen scaling.
6. Do not commit premium-only downloads, scraped preview images, fonts, or files whose license cannot be verified.
7. Before release, verify the current license for each exact item. CraftPix's current freebie license permits use and modification in personal/commercial projects and distributing a game containing the assets, but prohibits reselling or redistributing the artwork as standalone/reusable files. No attribution is required for freebies, though credit is appreciated.
8. **Do not upload CraftPix assets to AI systems for training, fine-tuning, testing, validation, or improvement.** CraftPix's license explicitly prohibits AI/ML use of licensed assets, including free assets and derivatives. Keep visual inspection and asset processing local unless the license terms are changed or CraftPix confirms permission in writing.

## Selection gate

An asset is accepted only if it:
- makes a real screen clearer or more engaging;
- fits the chosen PyQuest visual direction rather than making the whole app look like a preschool game;
- is technically usable in Flutter at phone scale;
- has a verified source and license;
- is optimized and does not unnecessarily inflate the APK.

## Important status

This document is a shortlist for investigation, not evidence that the assets have been downloaded, license-reviewed for a specific release, or integrated. Update this file with exact products and manifest entries only after inspecting the actual archives.
