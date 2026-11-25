# ELFIS Door Profile Library — 2.0.0

An update to the separate door-replacement extension. The original “Drzwi z zaznaczonego profilu” extension remains separate.

## Open the library

Click the new **three-panel library icon** beside the existing door-replacement icon. Or choose **Extensions → ELFIS — Biblioteka profili drzwi**.

The included profile is Bastille 84 × 22 mm. Door previews are schematic; the small cross-section preview displays the stored outline.

- Search by name. Use the star to mark a favourite and **Ulubione** to filter favourites.
- Select a card to make it the active profile. This choice is remembered.
- **Wybierz i klikaj fronty** closes the library and activates replacement. Click the exterior face of each front, including components inside closed groups. The existing quick replacement icon also uses the active profile.
- **Utwórz z wymiarów** creates a new door using the height and width entered in millimetres, at the origin of the current editing context. Ctrl+Z undoes creation.

## Add your own cross-section

1. In SketchUp, draw or import one closed planar cross-section at its actual size. Select its face, its closed edge loop, or a group containing that single cross-section. A finished 3D rail is not a cross-section.
2. Open the library and click **Dodaj z zaznaczenia**.
3. Check the cross-section preview and enter a name. The long straight edge is used to infer the profile orientation, as in the original profile tool.
4. Set **Płaska część ramy**: the width from the outside edge to the start of the inner moulding. For Bastille this is 75.5 mm. For a plain Shaker rail this can equal the full rail width.
5. Set panel thickness (**Płycina**) and clearance (**Luz płyciny**). A panel requires a recognised rectangular groove. Enter 0 for a frame without a panel. The panel must be thinner than the groove opening.
6. Click **Zapisz ustawienia jako profil**. The profile becomes available for both creation and replacement.

Editing the bundled Bastille settings saves a custom copy. Editing a custom profile updates that profile. Save changed settings before creating or replacing doors. The library currently has no delete or import/export buttons.

## Position and machining

The selected profile controls rail width and door thickness; thickness is no longer fixed to 22 mm. Replacement preserves the old back plane when the exterior face is clicked, so extra thickness extends outward. Source front thickness must be greater than 0.1 mm and no more than 80 mm. Door width and height must exceed twice the selected rail width.

All groups and component instances directly inside the old front are copied with nested contents, names, tags, attributes and world position. Raw old panel faces are replaced. Existing cutouts made only in raw panel geometry are not recreated. Machining depths are not recalculated. Exporting DXF with OpenCutList has not been retested for this update.

Already generated doors are protected from repeat replacement. Undo the earlier replacement to choose a different style. Shared cabinet instances are isolated along the clicked path, as in version 1.3.

## Storage and installation

User profiles, favourites and the active selection are stored outside the extension in `%APPDATA%\ELFIS\DoorProfileLibrary\profiles.json`. Back up that file to keep your library. The original DXF is not required after saving a profile. There are no online dependencies.

Install `ELFIS_Profile_Library_2.0.0.rbz` through **Extensions → Extension Manager → Install Extension**, then restart SketchUp. This updates the existing replacement extension rather than installing another copy. Version 1.3 remains available as a rollback package.

## Verification

Tested in SketchUp 2026: selection-to-library for a 70 × 22 mm Shaker cross-section, persistence and favourites after reloading, five manifold parts for a custom door, replacement with an 18 mm profile, fixed back plane, machining-container preservation, undo, and rejection of a panel too thick for its groove. The visual picker rendered in SketchUp and its favourite/filter controls were exercised. Test geometry was undone; the kitchen model was not saved by the test.
