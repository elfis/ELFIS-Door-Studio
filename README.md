# ELFIS Door Studio

Free, open-source SketchUp tools for cabinet fronts, handles and order lists. English is the default; Polish is selectable.

| Module | Current version | Installer | Guide |
| --- | --- | --- | --- |
| ELFIS Doors | **2.9.3** | [Download RBZ](public/2.9.3/ELFIS_Profile_Library_2.9.3.rbz) | [English](elfis_bastille_podmien_front/docs/USER_GUIDE.en.md) / [Polski](elfis_bastille_podmien_front/docs/USER_GUIDE.pl.md) |
| ELFIS Handles | **1.1.4-beta** | [Download RBZ](public/handles/1.1.4-beta/ELFIS_Handles_1.1.4-beta.rbz) | [English](ELFIS_Handles_README.en.md) / [Polski](ELFIS_Handles_README.md) |

**Handles remains beta.** Calibrate imported standard handles and check fixing points and placement on a test front. No manufacturer handle models are bundled. Handles requires Doors 2.9.1 or newer; use Doors 2.9.3 for the combined order window and PDF export.

## What it does

- Create **Five-Piece, One-Piece, Slab and J-Pull** fronts from reusable profiles, with dimensions and supported low-drawer variants.
- Replace nested front components from outside cabinets. Preserve supported machining containers, colour, tag and optional existing names; isolate shared cabinet occurrences.
- Preserve broad-face and individual narrow-edge materials when replacing with **Slab**, including existing OpenCutList edge-band material assignments. Previously lost assignments require an original front or backup.
- Manage profiles, favourites, manufacturers/sources and English/Polish interfaces.
- Prepare one order window with separate **fronts, End Panels and ELFIS handles** tables, quantities, dimensions and product details. Filter front/panel rows, highlight/zoom occurrences and replace selected front profiles.
- Copy tables or **export one complete PDF** with separate product sections, repeated headings, page numbers and selectable Unicode text. PDF export refreshes model data, ignores table filters/selection and includes all sections; hidden-element and Facade settings still apply.
- Import your own SKP handles, calibrate fixing points, place/replace them by clicking fronts and keep per-front settings during supported door changes. The **red X at the end of the action row** removes ELFIS handles from clicked fronts; it does not delete doors.

[Full feature list and shortcuts](FEATURES.md) · [Changelog: both modules](CHANGELOG.md) · [Door development history](elfis_bastille_podmien_front/docs/CHANGELOG.md) · [Roadmap](elfis_bastille_podmien_front/docs/ROADMAP.md)

## Install or update

1. Download the current RBZ packages above. Install Doors first, then the optional Handles module.
2. In SketchUp choose **Extensions → Extension Manager → Install Extension** for each package.
3. **Fully close SketchUp and start it again.** Installing new files can leave old Ruby code active until restart. Save your work first.
4. Enable **View → Toolbars → ELFIS — Doors / ELFIS — Handles** if necessary.

The Doors toolbar has replacement, profile-library and order-list buttons. Handles has a separate toolbar button. In-app help: **Extensions → ELFIS — Documentation / Dokumentacja**. The older “Drzwi z profilu” generator is a separate extension and is not required.

## Handle shortcuts

| Tool | Ctrl | Shift | Alt |
| --- | --- | --- | --- |
| Standard handles | Tap: horizontal top centre ↔ vertical top right | Tap: top/bottom centre when horizontal; top right/left when vertical | — |
| Edge pulls | Hold: right edge | Hold: bottom edge | Hold: left edge |
| J-Pull **door** replacement | Hold: left recess | Hold: bottom recess | Hold: right recess |

Standard-handle taps remain active after release. Dialog edits or restarting the placement tool reset the shortcut position. **Esc** exits click tools; **Ctrl+Z** undoes a placement/removal. In the front/panel order table, Shift selects ranges and Ctrl toggles individual rows; double-click zooms.

## Libraries, compatibility and limits

- Door profiles: `%APPDATA%\ELFIS\DoorProfileLibrary\profiles.json`.
- Handle library: `%APPDATA%\ELFIS\HandleLibrary\handles.json` and its `models` folder.
- Back up those user libraries separately. Earlier RBZ versions remain in `public/`; code rollback does not roll back library data.
- Tested on **SketchUp Pro 2026 / Windows**. Other versions and macOS are unverified. Five-Piece construction uses solid operations.
- Handle ordering recognises ELFIS-marked placements; unmarked manual handles are excluded. A source handle library is not needed to count saved placements.
- This version does not generate handle drillings. Manually scaling a front scales its nested handle; reapplying the handle tool restores its physical size.
- The PDF exporter embeds a system TrueType font (Arial on Windows), without Python or a separate PDF application. Review order notes before sending.

## Development and validation

Source for both modules is included. Package with `python package_elfis_library.py` or `python package_elfis_handles.py`; existing changed archives are never overwritten. Geometry checks require SketchUp; browser checks require Node.js and Playwright. Before packaging Handles, run test_elfis_handles.rb and test_elfis_handles_calibration_cancel.rb in SketchUp to generate the required passing reports; the calibration check needs an imported standard handle. See [validation notes](VALIDATION.md).

The installer filenames retain the original ELFIS Profile Library naming for compatibility. Version directories in `public/` are download archives; the GitHub **Releases** tab is a separate publishing channel and may list older releases.

## License and support

[MIT License](LICENSE). Free to use; donations are optional. [Ko-fi support](https://ko-fi.com/elfis1920) helps cover the AI credits used for development and testing. Rights to imported third-party models remain with their owners.
