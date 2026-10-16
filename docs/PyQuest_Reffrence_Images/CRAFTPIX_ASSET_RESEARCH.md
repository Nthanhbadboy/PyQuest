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


| P0 | Free Sci-Fi Platformer 1-Bit Pixel Art Game Kit | https://craftpix.net/freebies/free-sci-fi-platformer-1-bit-pixel-art-game-kit/ | Alternative direction for older learners: quest maps, futuristic challenge rooms and technology-themed worlds. | Strong monochrome 1-bit pixel style; only use if PyQuest intentionally adopts pixel art for the game-world layer. |
| P1 | Free Basic Pixel Art UI for RPG | https://craftpix.net/categorys/pixel-art-game-ui/ | Explore a compact, more restrained UI family for game-mode overlays and status elements. | Pixel style should stay inside the game-world layer, not leak into the lesson editor or AI Tutor. |
| P1 | Free Alphabet Vector Asset Kit for Education Games | https://craftpix.net/freebies/free-alphabet-vector-asset-kit-for-education-games/ | Secondary reference for reusable education symbols and interaction states. | Explicitly aimed at early learning and uses pastel/kawaii art; low priority for PyQuest's core UI. |

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

**Download gate confirmed:** the official free-download links for the Kids Math kit and Island GUI currently redirect to a CraftPix sign-in page. An account/login is required before the archive can be downloaded. No archive was downloaded during this research pass; do not claim that assets have been added to the repo.

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

## Public-repository rule

Do not commit downloaded ZIPs, raw artwork, preview screenshots, or extracted assets into this public reference folder just to build a gallery: the CraftPix license prohibits redistributing source art separately. Keep a source/asset manifest here. If an asset is selected for the actual PyQuest app, include only the specific optimized files used by the running app under the applicable license and ensure they are not exposed as standalone downloadable artwork. For visual references in this folder, prefer links to the official pages and original app screenshots created by the project team.


## New source: free animated characters with direct downloads (no account)

**Best verified source for immediate sprite-sheet candidates:** AutoSprite Free Library — https://www.autosprite.io/free-sprite-sheets

The official library states that its downloadable character sprite sheets are CC0, usable commercially, require no attribution, and have no sign-up gate. Each page exposes a direct ZIP URL plus PNG sheets and JSON atlas files. This is a better fit for testing than CraftPix's sign-in-gated downloads.

| Candidate | Official page | Animation content | Direct ZIP (no login shown) | Best role / limitation |
|---|---|---|---|---|
| Forest Druid | https://www.autosprite.io/free-sprite-sheets/forest-druid | Idle, walk, run; 75 frames; 384×384 frames | https://pub-63ab27389d044634a73e89c1a0c6d4a6.r2.dev/free-library/sprite-sheets/forest-druid/forest-druid.zip | Best candidate to test as a moving village character; fantasy look may be too dramatic for ordinary villagers. |
| Hooded Blade | https://www.autosprite.io/free-sprite-sheets/hooded-blade | Idle, run, attack, jump; 95 frames; 512×512 frames | https://pub-63ab27389d044634a73e89c1a0c6d4a6.r2.dev/free-library/sprite-sheets/hooded-blade/hooded-blade.zip | Hero / quest NPC, not a crowd villager; larger frames mean optimize before shipping. |
| Knight | https://www.autosprite.io/free-sprite-sheets/knight | Check page before selection | Open the product page and use its direct ZIP link | Potential guard / arena NPC; verify animation list and style first. |
| Wanderer | https://www.autosprite.io/free-sprite-sheets/wanderer | One 64-frame motion clip; 512×512 frames | https://pub-63ab27389d044634a73e89c1a0c6d4a6.r2.dev/free-library/sprite-sheets/wanderer/wanderer.zip | Atmospheric roaming character only; it is not documented as separate idle/walk/run states. |
| Dancer | https://www.autosprite.io/free-sprite-sheets/dancer | One 64-frame motion clip; 512×512 frames | https://pub-63ab27389d044634a73e89c1a0c6d4a6.r2.dev/free-library/sprite-sheets/dancer/dancer.zip | Optional plaza activity; not a general NPC. |

More direct candidates: Knight, Alchemist, Twin-Dagger Rogue, Arcane Mage, Red Dragon, Witch, Ninja, Paladin, Goblin and Dancer are listed at https://www.autosprite.io/free-sprite-sheets. Do not assume all have the same animation states; inspect each item page.

**Important technical caveat:** a free animated sheet is not automatically an isometric 2.5D villager. Before choosing, inspect its actual camera angle and frame consistency. AutoSprite's pages describe transparent PNG sheets plus JSON atlases, but the inspected Forest Druid and Hooded Blade prompts describe side-view characters, so they are proof of no-login animated assets—not yet approved as the final village art direction.

### Other no-account sources

- **Kenney Mini Characters (3D, animated, CC0):** https://kenney.nl/assets/mini-characters — official page lists 25 files, animation and CC0; the page has a “Continue without donating” route. Useful if the team wants to render 3D characters from a fixed isometric camera into sprites.
- **Kenney New Platformer Pack (2D, CC0):** https://kenney.nl/assets/new-platformer-pack — 440 files; check the included character animation states and whether its side-view style fits before use.
- **OpenGameArt OPP2017 sprites:** https://opengameart.org/content/opp2017-sprites-characters-objects-effects — more than 100 sprites/animations including villagers, animals and travelers. The page lists multiple licenses, so inspect the exact files and their license metadata before shipping; do not assume the whole archive is uniformly CC0.

### Download status / honest boundary

The official AutoSprite pages expose direct public ZIP links without a sign-in prompt. However, this ChatGPT execution environment could not retrieve the binary archive over its network, so **no ZIP or PNG has been committed to the repository yet**. Do not mark any candidate as downloaded or integrated until the actual files are present and inspected. Use the direct ZIP links above from a normal browser, then add only optimized, license-compatible assets to the app's runtime asset folder (not this reference folder).

## Important status

This document is a shortlist for investigation, not evidence that assets have been downloaded, license-reviewed for a specific release, or integrated. CraftPix downloads remain sign-in-gated. AutoSprite exposes direct no-sign-in download URLs, but the current tool environment could not retrieve their binary archives. Update this file with exact manifest entries only after inspecting the actual archives.
