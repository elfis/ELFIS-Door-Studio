# ELFIS Door Profile Library — 2.9.1

Create and restyle cabinet fronts from reusable cross-sections, then prepare a consolidated order list from the model.

The interface defaults to **English**. Choose **English / Polski** in the profile library or order-list header. The choice is remembered independently of the profile database. User profile names, materials, manufacturers, tags and existing component names are not translated.

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

Detailed instructions, controls and limitations are in [USER_GUIDE.en.md](USER_GUIDE.en.md). Polish instructions: [USER_GUIDE.pl.md](USER_GUIDE.pl.md). The installed extension also provides **Extensions → ELFIS — Documentation / Dokumentacja**.

See [CHANGELOG](CHANGELOG.md) for the archived development history and [ROADMAP](ROADMAP.md) for planned work. PDF export and a hardware-handle order list are planned, not present in 2.9.1.

## Your library

Custom cross-sections and settings are stored in `%APPDATA%\ELFIS\DoorProfileLibrary\profiles.json`, outside the installed extension. Back up this file before moving computers or rolling back to older code. A saved profile contains its section coordinates; its original DXF is no longer required.

RBZ release archives are kept separately; a code rollback does not automatically roll back or overwrite the user's profile data. Older versions may not understand newer profile types.

This package has been prepared for public testing. Publishing, licensing and distribution terms remain the author's decision; preparing the package does not publish it.
