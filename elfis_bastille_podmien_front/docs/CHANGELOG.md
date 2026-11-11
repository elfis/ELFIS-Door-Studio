# Changelog

This history is reconstructed from preserved RBZ packages, instructions, release notes and test reports. Older development dates were not consistently recorded, so none are invented. Version numbers belong to the named extension line; the first profile generator and the later replacement tool originally had separate version sequences.

## 2.9.3 — Complete PDF orders and Slab edge materials

- Export a single PDF containing separate doors/fronts, end panels and handles sections, with quantities, repeated table headers, page numbering and embedded Unicode fonts.
- Export fresh complete-model data independently of table filters/selection; retain the hidden-element and Facade inclusion settings. No Python, browser print dialog or external PDF library is required.
- Preserve front/back face materials and individual narrow-edge materials when replacing a front with an ELFIS Slab, including thickness changes, rotated/mirrored/scaled components and CNC containers.
- Isolate painted geometry from cached definitions and other component occurrences.

## 2.9.2 — Handles in the door order window

- Add a separate Handles table to the existing door/panel order window, with model, type, fixing pitch, length, finish, supplier, product code and consolidated quantities.
- Refresh and copy the complete order together, or copy only handles/panels. Front filters do not filter the handle table. Hidden-element visibility applies to both lists.
- Read mounted ELFIS records without requiring the handle library or Handles extension; retain per-occurrence counts in shared nested cabinets. Skip malformed records with a warning.

## 2.9.1 — One-Piece minimum-size validation

- Prevent a nominal 140 mm front from passing the 70 mm One-Piece section's size limit because a transformed measurement is fractionally above 140 mm.
- Check the remaining centre span with SketchUp's point tolerance at construction scale, both during target measurement and before generating geometry.
- Replace the native “Duplicate points in array” failure with a localised message showing the required size and received dimensions.
- Reject invalid replacements before changing the source component or machining containers. Valid small fronts and normal, curved and raised One-Piece profiles retain their geometry behaviour.

## 2.9.0 — English / Polish and public documentation

- English is the default interface language; English / Polski selection in both main windows, persisted separately from profile data.
- Localised library/order windows, native commands, tool hints, validation messages and clipboard headings. User names and profile geometry are preserved.
- English and Polish user guides with toolbar controls, import workflows, keyboard/mouse shortcuts, ordering, machining behaviour and limitations.
- In-app documentation command, archived changelog, current feature inventory in the guides, and a separate roadmap.
- This release does not implement PDF export or a hardware-handle list.

## 2.8.2 — Existing End Panels tag

- Recognise End Panels / endpanels with case, whitespace, underscore and hyphen variations.

## 2.8.1 — Separate Endpanels sublist

- Tag-based end-panel ordering without importing panel profiles.
- Separate panel quantities/table/copy button in the existing order window.
- Highlight, zoom, filters and manufacturer assignment for panels.
- Block door-profile replacement for panel rows or mixed front/panel selections.
- Nested panel body measurement excludes vector-only CNC containers.

## 2.8.0 — Families, low drawers and order-list controls

- Height-based profile families: standard frame and plain/custom-section low drawer.
- Import complete drawer sections while preserving moulding at both edges.
- Automatic, Framed and Low drawer overrides; family dimension validation.
- Bundled Bastille-specific dimension rules.
- Double-click order rows to zoom; combined profile/colour/manufacturer filters.
- Copy filtered visible rows.
- Expand ELFIS/Facade into a single manufacturer/source field, including OS Doors, BA, Tade Moldings and custom names.
- Assign manufacturer metadata to existing listed occurrences without rebuilding geometry.

## 2.7.1 — Multiple order rows

- Shift range selection, Ctrl toggle and Ctrl+Shift additive ranges.
- Highlight and replace all occurrences belonging to selected rows.
- Preserve individual J-pull handle edges in batch replacement.

## 2.7.0 — Restyle from the order list

- Choose a new profile and replace all front occurrences belonging to a list position.
- Isolate shared cabinet paths; preserve materials, tags, machining and rear plane.
- One undo step for the whole batch; rollback on an invalid/locked target.

## 2.6.3 — Nested editing overlay position

- Fix displaced order-list highlights while editing a group/component.

## 2.6.2 — Invalid overlay recovery

- Recreate removed/invalid SketchUp overlays before highlighting order items.

## 2.6.1 — Highlight from the list

- Clicking a consolidated row highlights all its front occurrences in the model.
- Clear highlight on request, refresh or close; retain ordinary model selection/edit context.

## 2.6.0 — Door order window

- Third toolbar button; consolidated front dimensions, quantities, type, colour and J-pull edge.
- Recognise ELFIS doors through attributes, including nested/scaled/mirrored occurrences.
- Optional Facade-tagged ordinary fronts with external-item marking and no double-counting.
- Hidden-element option, material/review warnings and tab-separated clipboard output.
- Store profile identity/specification with newly generated doors.

## 2.5.1 — Profile removal and preview layout

- Red bin with confirmation; delete custom profiles or hide built-ins.
- Restore built-ins, maintain favourites/active profile and protect the last available profile.
- Align section previews, scale and captions across cards.

## 2.5.0 — One-Piece Door

- Rename the separate-frame construction Five-Piece Door; introduce integral One-Piece Door.
- Import a suitable border-to-centre section and build one solid with a continuous centre.
- Support valid raised-centre and segmented-curve sections.
- Add a demo; preserve repeated restyling, machining containers and rear-plane anchoring.

## 2.4.1 — Native definition-name collision handling

- Remove recursive live-model naming scans/indexes in favour of native naming and direct definition lookups.
- Protect trailing dimension digits from SketchUp's numeric suffix interpretation.
- Preserve the selected profile/size base; duplicate numbering now starts at #1.

## 2.4.0 — Hover and geometry performance

- Reuse target measurements, preview geometry, tooltips and redraw work while the target is unchanged.
- Reuse matching generated geometry with a bounded 12-variant cache and independently editable results.
- Invalidate caches after model edits, undo/redo or context changes.
- Introduce a naming index; this particular strategy was superseded in 2.4.1.

## 2.3.3 — Replacement-tool preview

- Fix hover outlines in an open editing context.
- Blue target outline and green J-pull handle-edge preview.

## 2.3.2 — Optional renaming

- Menu choice: keep original door names (default) or rename to profile and size.
- Persist the option; skip naming searches in preserve-name mode.

## 2.3.1 — Profile-and-size names

- Rebuild names from the selected profile and height × width instead of repeatedly appending old J-pull names.
- Add a custom duplicate suffix beginning at #2; later replaced by the 2.4.1 strategy.

## 2.3.0 — J-pull click modifiers

- Shift: bottom; Ctrl: left; Alt: right; no modifier: saved edge.
- Immediate handle-edge preview when modifiers change.

## 2.2.1 — Parametric J-pull recess correction

- Correct the generated recess orientation relative to the panel faces; retain the flat rear plane.
- Custom sections keep their explicit front/back settings.

## 2.2.0 — J-pull profiles

- Parametric J-pull generator and custom full-section import.
- Four handle edges, front/back/end flips and geometric validation.
- Restyle between Slab, framed and J-pull fronts.

## 2.1.0 — Slab and repeated restyling

- Plain Slab profiles using thickness without a cross-section.
- Repeated style changes of already generated fronts, replacing old generated geometry while preserving auxiliary containers.

## 2.0.0 — Door Profile Library

- Visual profile cards, section previews, search, favourites and a remembered active profile.
- Custom cross-section import and saved settings.
- Creation by dimensions and replacement using the active profile.
- User JSON library outside the extension; source DXF not required after import.
- Profile-controlled thickness, preserved rear plane and machining containers.

## Replacement tool 1.3.0 — Rear-plane anchoring

- Retain the old back plane when replacement thickness changes; expand outward.
- Keep machining-vector positions and recorded depths rather than guessing a thickness offset.

## Replacement tool 1.2.0 — Machining containers

- Preserve groups/components inside the source front, including nested contents, names, tags, attributes and world position.

## Replacement tool 1.1.0 — Nested component picking

- Pick a front component through closed cabinet groups/components.
- Isolate shared cabinet copies along the clicked path and create a component result.

## Replacement tool 1.0.0 — Click to replace

- Separate Bastille replacement extension with a bundled 84 × 22 mm section.
- Read the clicked front dimensions and create matching Bastille doors.
- Support rotation, scaling, mirroring and undo.

## Original profile generator 1.1.0 — Toolbar packaging

- Door toolbar button and Extensions command for the selected-section generator.
- Installable package and usage instructions.

## Original profile generator 1.0.0 — Selected-section construction

- Generate a frame door from a selected planar face, closed outline or section group and entered dimensions.
- Flat 90° frame shoulders, internal moulding around the panel, optional separate panel and parameter validation.

## Before numbered packages

The initial Bastille 715 × 596 mm model and scripts explored 45° versus 90° joints, then corrected the frame so the groove/moulding stayed around the central panel instead of remaining exposed at outer ends. These are development artefacts, not separately verified numbered public releases.

## Evidence

The preserved history includes both original extension instruction files, 2.0/2.1/2.2/2.3 instructions, individual 2.3.1–2.6.3 notes, 2.7.0/2.7.1 readmes and 2.8.0–2.8.2 readmes. Exact archive names and SHA-256 hashes are recorded in RELEASE_ARCHIVES.json. Public documentation describes current behaviour; historical notes describe the corresponding old version and may contain superseded limitations.
