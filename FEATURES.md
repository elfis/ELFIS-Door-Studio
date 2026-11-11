# Features and controls

Current: **Doors 2.9.3 / Handles 1.1.4-beta**. [Door guide](elfis_bastille_podmien_front/docs/USER_GUIDE.en.md) · [Handle guide](ELFIS_Handles_README.en.md)

| Area | Available functions |
| --- | --- |
| Front construction | Five-Piece, One-Piece, Slab, J-Pull; create by height/width; supported automatic low-drawer variants |
| Profile library | Import selected planar cross-sections; add profiles; configure names, dimensions, suppliers and variants; search, favourites, remove custom profiles/hide built-ins |
| Replacement | Click nested front components; isolate shared cabinet copies; retain supported machining containers, colour/tag and optional names; preserve individual face/edge materials when replacing with Slab |
| Order window | Separate fronts, End Panels and ELFIS hardware tables; quantities, dimensions, colours, product/supplier/code information; include Facade and hidden-element options |
| Front/panel list actions | Profile/colour/source filters; click to highlight; double-click to zoom; Shift ranges; Ctrl toggles; batch profile replacement for front rows; supplier assignment |
| Export | Clipboard tables; complete-order PDF with separate product sections, repeated headings, page numbering, selectable Unicode text and review notes |
| Handle library | Import standard handles, knobs and edge pulls from SKP; edit product details; remove library records; calibrate fixing points without changing source axes |
| Handle placement | Click fronts, apply to selected fronts, replace all marked handles; independent offsets; frame auto offsets; preserve per-front settings; re-seat handles on supported door-style/thickness changes |
| Handle removal | Red X at the end of the action row; click fronts to remove marked handles only; retained fittings/CNC groups; Esc exits; Ctrl+Z undoes |
| Interface | English default / Polish option; translated guides, tooltips and dialogs |

## Shortcuts

- Standard handles: **tap Ctrl** for horizontal top centre ↔ vertical top right. **Tap Shift** for horizontal top/bottom centre or vertical top right/left. Release retains the choice; dialog edits/restarting placement reset it.
- Edge pulls: **hold Ctrl = right, Alt = left, Shift = bottom**.
- J-Pull door replacement: **hold Ctrl = left, Alt = right, Shift = bottom**. These are separate tool mappings.
- Placement/removal: **Esc** exits; **Ctrl+Z** undoes a committed model operation.
- Calibration: select fixing centres and contact surface; **Tab** reverses the contact normal; cancel or Esc in the model viewport discards the temporary sample.
- Front/panel order rows: click highlights, double-click zooms; Shift selects a range and Ctrl toggles individual rows.

PDF export includes the entire order, independent of table selection, filters or section checkboxes; hidden-element and Facade settings apply. Front filters do not limit the hardware table.

## Current limits

Handles is beta and does not generate drillings. Unmarked manual handles are not counted. Manual front scaling scales nested handles until the tool is reapplied. Other SketchUp versions/macOS are unverified. See the guides for geometry, calibration and machining limitations.
