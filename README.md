# ELFIS Door Studio

Free, open-source SketchUp tools for cabinet fronts, handles, drilling vectors, shelf arrangement and order preparation. English is the default; Polish is selectable.

Designed to support workflows with **Blum Online Configurator, ABF2 and OpenCutList**. This is an independent project, not an official product or endorsement of those vendors.

**Development status:** New feature development is on hold until **OpenCutList 8.0**. Many planned features depend on or are intended to work with OpenCutList; their design will be reviewed against that release before development resumes. The features documented below are already implemented. No OpenCutList 8.0 compatibility is claimed in advance.

## Downloads

| Module | Version | Installer | Documentation |
| --- | --- | --- | --- |
| Doors and cabinet tools | **2.9.46** | [Download RBZ](public/2.9.46/ELFIS_Profile_Library_2.9.46.rbz) · [SHA-256](public/2.9.46/ELFIS_Profile_Library_2.9.46.sha256) | [Release notes](public/2.9.46/README.md) · [English](elfis_bastille_podmien_front/docs/USER_GUIDE.en.md) · [Polski](elfis_bastille_podmien_front/docs/USER_GUIDE.pl.md) |
| Door Configurator and finishes | **3.0.1-beta** | [Download RBZ](public/3.0.1-beta/ELFIS_Profile_Library_3.0.1-beta.rbz) · [SHA-256](public/3.0.1-beta/ELFIS_Profile_Library_3.0.1-beta.sha256) | [Release notes](public/3.0.1-beta/README.md) · [English](public/3.0.1-beta/docs/USER_GUIDE.en.md) · [Polski](public/3.0.1-beta/docs/USER_GUIDE.pl.md) |
| Handles | **1.1.10-beta** | [Download RBZ](public/handles/1.1.10-beta/ELFIS_Handles_1.1.10-beta.rbz) · [SHA-256](public/handles/1.1.10-beta/ELFIS_Handles_1.1.10-beta.sha256) | [Release notes](public/handles/1.1.10-beta/README.md) · [English](ELFIS_Handles_README.en.md) · [Polski](ELFIS_Handles_README.md) |
| Cabinet Studio | **3.1.0** | [Download RBZ](public/CabinetStudio/3.1.0/ELFIS_Cabinet_Studio_3.1.0.rbz) · [SHA-256](public/CabinetStudio/3.1.0/ELFIS_Cabinet_Studio_3.1.0.sha256) | [Notes](public/CabinetStudio/README.md) |
| Drilling, Edge & Tag Highlight | **1.3.1** | [Download RBZ](public/DrillingHighlight/1.3.1/ELFIS_Drilling_Highlight_1.3.1.rbz) · [SHA-256](public/DrillingHighlight/1.3.1/ELFIS_Drilling_Highlight_1.3.1.sha256) | [Release notes](public/DrillingHighlight/1.3.1/README.md) |
| Cabinet Elevation / Widok Zabudowy | **0.1.44 beta** | [Download RBZ](public/elevation-beta/ELFIS_Widok_Zabudowy_0.1.44_beta.rbz) · [SHA-256](public/elevation-beta/ELFIS_Widok_Zabudowy_0.1.44_beta.sha256) | [Release notes](public/elevation-beta/README.md) |
| Hinge Hardware Sync | **0.1.2 test** | [Download RBZ](public/hinge-hardware-sync/0.1.2-test/ELFIS_Hinge_Hardware_Sync_0.1.2_TEST_code_only.rbz) · [SHA-256](public/hinge-hardware-sync/0.1.2-test/ELFIS_Hinge_Hardware_Sync_0.1.2_TEST_code_only.sha256) | [Release notes](public/hinge-hardware-sync/0.1.2-test/README.md) |

Install RBZ packages from **Extensions → Extension Manager → Install Extension** and restart SketchUp. Enable toolbars under **View → Toolbars**. Install Doors 2.9.46 before Cabinet Studio. The Doors 3.0 beta uses the same extension files as 2.9 and focuses on front finishes. Use the 2.9 series for cabinet machining tools and back up your extension settings before switching series. Handles is an optional add-on.

[Installer archive](INSTALLER_ARCHIVES.json) · [Tag Toolbar](public/TagToolbar) · [Cabinet Preview test builds](public/cabinet-preview) · [Upper Front Positioning test builds](public/upper-front-positioning) · [Legacy front tools](public/legacy)

Tested in **SketchUp Pro 2026 on Windows**. Other SketchUp versions and macOS have not been verified. Handles remains beta: calibrate fixing points and check a test front before production use.

## Features

- **Fronts:** create Five-Piece, One-Piece, Slab and rear-cut J-Pull doors from reusable profiles; profile families and supported low-drawer variants; optional slab front chamfer.
- **One-click replacement:** target nested front components from outside a cabinet; preserve supported machining containers, material, tag and optional original naming; isolate shared cabinet occurrences. Replacements retain the back plane while taking thickness from the chosen profile.
- **Profile library:** custom cross-sections, saved settings, search, favourites, manufacturer/source information, previews, custom-profile deletion and restoration of hidden built-ins. English/Polish interface.
- **OpenCutList material workflow:** retain Slab edge-band materials on narrow faces and allow component-axis/grain changes without baked broad-face texture mapping. Colouring stays in SketchUp/OpenCutList; the experimental V-Ray colour configurator is not included.
- **Handles:** import your own SKP library, calibrate mounting points, automatically measure length, place/replace/remove handles on nested fronts, choose orientation and offsets, and retain supported per-front settings during door changes. Rear-fixed edge pulls include side offsets from centre. Separate library, add and remove toolbar commands.
- **Order window:** consolidated front quantities and dimensions, materials, profiles and sources; optional starred Facade items; separate Finishing groups and handle table. Filters, sorting, click highlight, double-click zoom, Ctrl individual selection, Shift range selection and selected-front profile replacement.
- **Ordering output:** clipboard tables and one print-friendly portrait A4 PDF containing fronts, Finishing products, handles and stock plans; bold quantity before dimensions, project-based suggested filename.
- **Plinth stock planning:** configurable stock length and saw kerf, whole-length quantities, expandable cutting trees and waste. Different widths can share lengthwise offcuts, with an option to separate widths. Products, materials, thicknesses and suppliers stay separate.
- **Shelf-pin drilling:** configurable diameter, depth, pitch, front/rear offsets and extra holes above/below; grouped machining vectors, click insertion, Alt removal and Ctrl regeneration.
- **Dowels and screws:** configurable 21-spindle / 32 mm source-panel pattern for rails and fixed shelves; offsets measured from the rail/shelf front, not the cabinet side; side and exterior-back screw operations with real-contact validation.
- **Hinge drilling:** Ø35 cup and two Ø8 front fixings with corresponding Ø5 cabinet-side drilling; count, top/bottom offsets and hinge side in a viewport panel; live preview, +/−, wheel and exact input. Saved per-front layouts survive Refresh.
- **TANDEMBOX drilling:** the validated **M/D, 500 mm screw-on pilot/gallery reference pattern**, referenced to drawer fronts and overlays. Includes adoption, removal and refresh. Other lengths, MERIVOBOX and physical drawer models are not implemented.
- **Kamar hanger cutouts:** exterior L-shaped routing vectors and through-cut geometry; independent Left / Right / Both layouts per back, Ctrl cycling, Alt removal/filling and legacy geometry recognition without ELFIS attributes.
- **Arrange Shelves:** viewport count controls, visible clear openings, equal spacing or mixed fixed-mm/weighted gaps from bottom to top; deduct actual rail/shelf thickness, clone/remove shelves and rebuild supports in one Undo operation.
- **L-shaped corner cabinets:** retain full rounded L shelf outlines; use real perpendicular panel contacts; preserve recognized side and exterior through-back support layouts, independent back joints and asymmetric hanger cutouts; hinge sides follow mirrored fronts.
- **Refresh drilling:** regenerate owned drilling and remove recognized orphan supports after deleting shelves, within one Undo operation. No continuous geometry refresh while orbiting.
- **Existing drilling:** recognize and adopt supported imported drilling groups, associate source panels, convert supported parameters and retain unrelated machining. Ambiguous geometry is left for review.
- **Default settings and visibility:** central drilling defaults, configurable panel-tag roles and visibility buttons for selected tags or named groups. Door-profile settings stay in the profile library.

[Detailed features, controls and shortcuts](FEATURES.md) · [Full changelog](CHANGELOG.md) · [Validation and limits](VALIDATION.md) · [Roadmap](ROADMAP.md)

## What changed since the previous GitHub release?

Doors **2.9.40–2.9.46** adds configurable toolbars, cabinet drilling cleanup, Dowels and Screws 2.0 and Arrange Shelves 2.0. The separate **3.0.1-beta** adds component-level finishes and grain controls. [Version-by-version changes](CHANGELOG.md).

Handles **1.1.10-beta** adds shared toolbar preferences for ordering and hiding the Add, Remove and Library buttons.

## Validation and machining limits

The historical Doors 2.9.39 validation record contains **248 passing native checks**, including 88 corner-cabinet checks on disposable copies. Two historical harnesses relying on absent/changed production fixtures are excluded and documented separately. This is not certification of arbitrary cabinets or every manufacturer's drilling pattern. Review all generated vectors, tags, depths and clearances before machining. Follow the fitting manufacturer's current technical documentation.

No manufacturer hardware models, hinge/drawer opening animation, collision physics, V-Ray colour library or automatic plinth geometry generator are bundled. Shelf arrangement supports the documented upright single-bay geometry; arbitrary skewed intersections and ambiguous panel layouts are rejected.

## License and support

[MIT License](LICENSE): free to use, modify and share. Third-party profiles, textures and imported SKP models retain their owners' rights.

Optional [Ko-fi donations](https://ko-fi.com/elfis1920) help pay for AI credits used in development and testing. Donations are not required to use the plugin.
