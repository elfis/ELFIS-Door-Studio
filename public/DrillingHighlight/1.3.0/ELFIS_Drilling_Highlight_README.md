# ELFIS Drilling, Edge & Tag Highlight 1.3.0

Standalone SketchUp 2023+ overlay, independent of ELFIS Door Studio.

## Use / Obsługa

The **ELFIS Drilling Highlight** toolbar has two independent switches and a tag-list button:

- **Drilling highlight ON/OFF** — red drilling circles, including hidden machining containers.
- **Edge banding highlight ON/OFF** — blue outlines of visible faces carrying an OpenCutList edge-band material. Select a cabinet, panel or several groups/components. Nested and transformed instances are supported. Empty selection clears the display.
- **Tag highlight list** — choose one or more tags in the ELFIS list to highlight their visible geometry with gold outlines. Search by tag/folder name. Clear, Escape or closing the window removes this temporary display. This does not read the selected row in SketchUp's native Tags tray.

Na pasku są dwa niezależne przyciski: czerwone wiercenia i niebieskie okleinowane krawędzie. Zaznacz szafkę lub panele; podświetlenie podąża za zaznaczeniem. Przyciski są też w menu Extensions / Rozszerzenia.

Move temporarily hides highlights; leaving Move restores them. Edge outlines refresh after model transactions, Undo/Redo and editing-context changes. Geometry is cached; orbiting only draws the cached lines. No model geometry, materials, tags or attributes are modified.

## OpenCutList compatibility

Reads `material.get_attribute('ladb_opencutlist', 'type', 0) == 4` on the **front side of faces**, as OpenCutList does. Names such as ABS are not used to guess edge banding. Component-level panel materials and back-face-only paint are not interpreted as edge banding.

Verified against installed **OpenCutList 7.1.0** and the source schema of the **8.0.0** branch. OpenCutList 8 runtime has not been installed or tested here.

Source references:

- https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/master/src/ladb_opencutlist/ruby/model/attributes/material_attributes.rb
- https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/8.0.0/src/ladb_opencutlist/ruby/model/attributes/material_attributes.rb
- https://github.com/lairdubois/lairdubois-opencutlist-sketchup-extension/blob/8.0.0/src/ladb_opencutlist/ruby/plugin.rb

## Installation

Install `ELFIS_Drilling_Highlight_1.3.0.rbz` through Extension Manager, then restart SketchUp if the previous script was loaded. Include the shared `elfis_menu.rb` and `elfis_drilling_highlight` resource folder. Commands are under **Extensions → ELFIS → Display & visibility**. Previous versions are preserved in Backups and immutable RBZ packages.

## Changelog

### 1.3.0

- Searchable tag list, multiple tag choices and temporary gold outlines.
- Tagged cabinets include their nested geometry; shared copies are handled per occurrence.
- Clear/Escape/window close disables the tag overlay and detaches its observers.
- Shared ELFIS menu categories; drilling and edge commands remain independent.

### 1.2.0

- Separate edge-banding overlay, toolbar icon and menu command.
- OCL material-type recognition shared by 7 and 8; independent of material names.
- Nested selection, per-instance transformations, visible faces only, soft seam suppression.
- Material transaction refresh without continuous geometry polling.
- Previous drilling toggle, selection following and temporary Move suppression retained.
