# ELFIS Drilling & Edge Highlight 1.2.0

Standalone SketchUp 2023+ overlay, independent of ELFIS Door Studio.

## Use / Obsługa

The **ELFIS Drilling Highlight** toolbar has two independent switches:

- **Drilling highlight ON/OFF** — red drilling circles, including hidden machining containers.
- **Edge banding highlight ON/OFF** — blue outlines of visible faces carrying an OpenCutList edge-band material. Select a cabinet, panel or several groups/components. Nested and transformed instances are supported. Empty selection clears the display.

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

Install `ELFIS_Drilling_Highlight_1.2.0.rbz` through Extension Manager, then restart SketchUp if the previous script was loaded. Source files and SVG icons belong directly in the Plugins directory. Version 1.1.1 is preserved in `Backups/DrillingHighlight_1.1.1`.

## Changelog

### 1.2.0

- Separate edge-banding overlay, toolbar icon and menu command.
- OCL material-type recognition shared by 7 and 8; independent of material names.
- Nested selection, per-instance transformations, visible faces only, soft seam suppression.
- Material transaction refresh without continuous geometry polling.
- Previous drilling toggle, selection following and temporary Move suppression retained.
