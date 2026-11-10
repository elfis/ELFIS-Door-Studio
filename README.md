# ELFIS Door Studio

Free, open-source SketchUp extension — version 2.9.1

[Download the installer](https://github.com/elfis/ELFIS-Door-Studio/raw/refs/heads/main/public/2.9.1/ELFIS_Profile_Library_2.9.1.rbz) · [Support development on Ko-fi](https://ko-fi.com/elfis1920)

Create and restyle cabinet fronts from reusable cross-sections, then prepare a consolidated order list from the model.

The interface defaults to **English**. Choose **English / Polski** in the profile library or order-list header. The choice is remembered independently of the profile database. User profile names, materials, manufacturers, tags and existing component names are not translated.


## Modules and downloads

| Module | Version | Download | Documentation |
| --- | --- | --- | --- |
| ELFIS Doors | 2.9.1 | [RBZ installer](public/2.9.1/ELFIS_Profile_Library_2.9.1.rbz) | [English guide](elfis_bastille_podmien_front/docs/USER_GUIDE.en.md) |
| ELFIS Handles | 1.1.1-beta | [RBZ installer](public/handles/1.1.1-beta/ELFIS_Handles_1.1.1-beta.rbz) | [English](ELFIS_Handles_README.en.md) / [Polski](ELFIS_Handles_README.md) |

**BETA — ELFIS Handles 1.1 adds standard-handle fixing-point calibration, live settings and Shift left/right placement. Calibrate imported standard handles and verify their placement on a test front.**

**ELFIS Handles requires ELFIS Door Studio 2.9.1.** It adds a separate toolbar icon, a library of user-imported SKP handles, click placement, batch replacement with saved positions, and its own consolidated handle order list. Door profile definitions remain unchanged. The handle library starts empty; imported models appear in a dropdown. See the handle guide for component axes and current limitations.

## Install or update

1. In SketchUp, choose **Extensions → Extension Manager → Install Extension**.
2. Select `ELFIS_Profile_Library_2.9.1.rbz` and restart SketchUp.
3. Enable the ELFIS toolbar through **View → Toolbars** if it is hidden.

This updates the existing door-replacement/profile-library extension. The older “Drzwi z profilu” generator is a separate extension and is not required.

Development and native testing have targeted **SketchUp Pro 2026 on Windows**. Other SketchUp versions and macOS have not been verified. Five-Piece construction uses solid operations.

## Three toolbar buttons

| Button | Action |
| --- | --- |
| Door with arrow | Replace the clicked front using the active library profile. Continue clicking additional fronts. |
| Profile library / three panels | Choose, add, configure or remove profiles; create doors by dimensions. |
| Order list | Refresh quantities and dimensions, highlight or zoom to items, change selected front styles, and copy tables. |

Detailed instructions, controls and limitations are in [USER_GUIDE.en.md](elfis_bastille_podmien_front/docs/USER_GUIDE.en.md). Polish instructions: [USER_GUIDE.pl.md](elfis_bastille_podmien_front/docs/USER_GUIDE.pl.md). The installed extension also provides **Extensions → ELFIS — Documentation / Dokumentacja**.

See [CHANGELOG](elfis_bastille_podmien_front/docs/CHANGELOG.md) for the archived development history and [ROADMAP](elfis_bastille_podmien_front/docs/ROADMAP.md) for planned work. PDF export and a hardware-handle order list are planned, not present in 2.9.1.

## Your library

Custom cross-sections and settings are stored in `%APPDATA%\ELFIS\DoorProfileLibrary\profiles.json`, outside the installed extension. Back up this file before moving computers or rolling back to older code. A saved profile contains its section coordinates; its original DXF is no longer required.

RBZ release archives are kept separately; a code rollback does not automatically roll back or overwrite the user's profile data. Older versions may not understand newer profile types.

## Door styles

- **Five-Piece:** frame-and-panel doors made from reusable cross-sections.
- **One-Piece:** continuous profiled fronts.
- **Slab:** flat fronts.
- **J-Pull:** handleless fronts with selectable handle orientation.

Profile families can include low-drawer variants. Replace nested components while retaining their colour, tag and supported machining groups. Review the user guide for geometry and machining limitations.

## Support development

ELFIS Door Studio is free to use. Optional donations help cover the AI credits used to develop and test the extension. Thank you for supporting future improvements!

[Donate on Ko-fi](https://ko-fi.com/elfis1920)

## Development

The extension source is included in this repository. To package it, run `python package_elfis_library.py`. Existing archives are preserved; use a new version number for a changed release. The included UI regression checks run with `node test_elfis_languages.cjs`, `node test_library_28.cjs` and `node test_order_multiselect.cjs`; native geometry testing requires SketchUp.

The public project is called ELFIS Door Studio. The 2.9.1 installer and existing code retain their original ELFIS Profile Library names for compatibility.

## License

[MIT License](LICENSE). Donations are optional and are not required to use the extension.
