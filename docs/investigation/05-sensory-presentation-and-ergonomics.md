# Dossier 05: Sensory Presentation & Ergonomics Investigation

**Focus:** Visual consistency, unit animation completeness, audio staging, camera dynamics, and interface ergonomics.  
**Primary Source Modules:** `src/ui/camera_rig.gd`, `src/area/tile_forge.gd`, `src/autoload/music.gd`, `src/autoload/sfx.gd`, `src/autoload/database.gd`, `src/ui/touch_controls.gd`, `art/ui/menu_theme.tres`  
**Reference Docs:** [docs/09-wishlist.md](docs/09-wishlist.md), [docs/10-manual-tests.md](docs/10-manual-tests.md)

---

## 1. Audiovisual & Interface Systems Architecture

_Earth Kings_ relies on a distinct retro-tactical aesthetic: high-contrast 16-bit pixel art, ornate 9-slice UI borders, atmospheric shaders, and a dual-bus audio pipeline.

### 1.1 The Unit Animation Deficit (The "Sworn Blade Island")

- **The Ideal Pipeline:** `Database.unit_run` caches multi-frame directional run cycles (`art/units/<id>/run/<heading>/frame_%03d.png`). Units step frames dynamically as they cross grid cells and turn corners.
- **The Reality:** Of the **69 unit templates** defined in `data/units.json`, exactly **one unit (`sworn_blade`)** possesses a rendered run cycle.
- **The Fallback:** The remaining 68 units slide across tiles while locked in their static directional standing poses ([Wishlist W11](docs/09-wishlist.md#L162)).
- **Critic's Assessment:** This creates a jarring aesthetic dichotomy. When Bram moves, the world breathes with mechanical life; when any companion, beast, or enemy commander moves, they levitate across the terrain like cardboard figurines on a tabletop.

### 1.2 Tile Synthesis & The Wang 24×8 Architecture (`TileForge`)

- **Format:** PixelLab 24×8 Wang tile sheets (1536×512 resolution).
- **Wang Indexing:** Uses bitwise cardinal corner matching (`NW8`, `NE4`, `SW2`, `SE1`).
- **The Seam Challenge:** Because each sheet’s grass utilizes a slightly different green palette, transitions between sheets must be buffered by 2 cells, and ragged outlines must be used to conceal seams. Rectangular transitions expose raw edges.

### 1.3 Audio Pipeline & Acoustic Staging

- **Music Autoload:** Two crossfading `AudioStreamPlayer` nodes operating on a dedicated runtime audio bus.
- **Dynamic Rotation:** Battle themes rotate systematically without repeating the same track consecutively (`data/music.json`).
- **Sound Effects:** Separate `Sfx` bus; `Sfx.attend` dynamically binds distinct hover and select sounds to UI buttons.

### 1.4 Camera Rig Architecture (`CameraRig`)

- **Unified Rig:** All views (World, Battle, Area, Overworld) route through `src/ui/camera_rig.gd`.
- **Invariants:** Setting raw camera position or zoom directly is strictly prohibited to prevent viewport desynchronization. The rig enforces boundary clamping (`frame(Rect2)`), smooth tracking (`focus_on`), and zoom limits.

### 1.5 Interface Complexity & Keyboard Clustering

- **Input Map Density:** World mode registers an intimidating array of keys:
  - **E:** Interact / Enter Site
  - **Q:** Toggle Auto-pace
  - **T:** Cycle Speed (1× / 2× / 4×)
  - **P:** Party Screen
  - **N:** Journal & Bestiary
  - **L:** Toggle World Log
  - **J:** Errands Board
  - **G:** Grimoires
  - **H:** Hire Mercenary
  - **B:** Market Buy
  - **R:** Ransom Captive
  - **F:** Rescue Captive
  - **U:** Upgrade Hearth Bed
  - **V:** Defend Town Siege
  - **K:** Raid Town Guard
- **Touch / Mobile Adaptation:** `TouchControls` overlays a virtual D-pad and contextual action cluster when `Pace.touch_mode` is enabled.

---

## 2. Identified Vulnerabilities & Stress Areas

### 2.1 The Visual Dissonance Shock

- When a new player recruits a party of four, the party consists of one fluidly running leader followed by three gliding statues. In battle, enemy cavalry and beasts slide stiffly across the grid. This severely undermines the gritty realism established by the narrative.

### 2.2 Key Clutter and Input Collisions

- The world map requires memorizing over 15 single-letter shortcuts. Earlier builds suffered from physical key collisions (e.g., `E` being double-bound to both speed cycling and site entry). The risk of cognitive overload for non-hardcore players is extreme.

### 2.3 UI Scale on Varied Displays

- Ornate 36px 9-slice border corners (`FramedPanel`, `GrandButton`) look sumptuous on desktop 1080p displays, but risk clipping or occluding vital text when rendered on smaller touch displays or ultra-wide setups.

---

## 3. Investigation & Benchmark Procedures

### Test Protocol 5.1: Animation Completeness & Asset Registry Audit

- **Objective:** Run automated audit across `art/units/` to map existing animation frames per unit ID.
- **Harness:** Run `tools/sprite_report.tscn` to generate a markdown matrix of missing walk, run, and attack frames.

### Test Protocol 5.2: Wang Tile Boundary Visual Probe

- **Objective:** Inspect all 18 interior and exterior area files (`data/areas/*.json`) for hard rectangular terrain borders or palette clashes.
- **Verification:** Execute visual probe script `.art_stage/wang_probe.ps1` to verify all corner transitions adhere to the 2-cell buffer rule.

### Test Protocol 5.3: Camera Viewport Boundary Stress

- **Objective:** Rapidly pan, pinch, and zoom camera during world transit and area navigation:
  ```powershell
  .\ek.ps1 --scene=world --shot
  ```
- **Verification:** Ensure camera never snaps to origin `(0, 0)` or exposes void space beyond map bounds.
