# Changelog

This history is reconstructed from preserved RBZ packages, instructions, release notes and test reports. Older development dates were not consistently recorded, so none are invented. Version numbers belong to the named extension line; the first profile generator and the later replacement tool originally had separate version sequences.

## 2.9.39 — L corner cabinet machining and shelf arrangement

- Detect actual shelf/rail edge contacts with perpendicular receivers; retain complete rounded L shelf outlines in arrangement previews and cloning.
- Adopt recognized imported corner supports and preserve edge-anchored row layouts, including exterior through-back rows with actual thickness.
- Arrange mixed openings, add/remove shelves, retain templates after zero and regenerate drilling atomically. Clean deleted-shelf supports in backs as well as sides.
- Generate L rail/fixed-shelf joinery from source-edge spindle datums and process each back/butt joint independently with real-face validation.
- Verify both perpendicular Blum fronts; retain per-front hinge side directions after mirroring.
- Preserve Kamar two-plus-one cutout layouts, copied cabinets, unrelated machining and materials. No background refresh.

## 2.9.38 — Independent Kamar back layouts

- Add viewport Left / Right / Both controls and Ctrl cycling; retain Alt removal and live corner preview. Tool activation no longer changes selected cabinets immediately.
- Determine the exterior independently for each back, including perpendicular corner-cabinet backs without two parallel side panels.
- Save per-back corner layouts; Refresh preserves asymmetric two-plus-one arrangements and adopts supported attribute-free legacy geometry.
- Preserve single-corner removal, material repair, unrelated drilling and cabinet-copy isolation. No timers or background observers.
- Corner shelves, joinery and corner hinge patterns remain pending; this release covers Kamar cutouts.

## 2.9.37 — Cabinet shelf arrangement

- Add Arrange Shelves with viewport count controls, equal-clearance distribution, mixed mm/weighted opening input and persistent dimension labels.
- Measure between rail faces and deduct actual shelf thicknesses before allocating openings, bottom to top. Preview changes before Apply.
- Clone template shelves when increasing count, remove topmost adjustable shelves when decreasing, retain a template after zero, preserve materials/tags and isolate copied cabinets.
- Regenerate associated shelf-pin drilling in the same Undo operation. Reject ambiguous compartments, locked panels, stale previews, unadopted imported support drilling and impossible clearances.

## 2.9.36 — Hinge tool viewport panel

- Add native viewport controls for count (2–10), top/bottom offsets and hinge side, with numbered axis-position labels and live preview. Click values for exact input, use +/− buttons or mouse wheel, then click a front to apply.
- Preserve normal wheel zoom away from fronts/controls. Reject invalid or overlapping hinge layouts without changing the model.
- Replace owned drilling when applying quick layout changes, including reductions in count and side changes. Store each front layout and preserve it through Refresh drilling; global defaults and current depth settings remain separate.
- Resolve Auto hinge side before removing old cups, preserving right-hand drilling during regeneration.
- Keep Alt removal, Ctrl regeneration, right-click settings and Esc; add no background observers or OpenCutList dependency.

## 2.9.35 — Reference dowel/screw rows to source rail front

- Fix the 21-spindle drilling datum: measure the first offset and 32 mm pattern from the rail or fixed shelf front, instead of the receiving side front. Recessed panels move their corresponding side holes by the same amount.
- Clip active spindles to the source depth and clarify the EN/PL settings labels. Preserve back-screw placement, inward thickness correction, copy isolation and ownership.
- Refresh drilling and Ctrl regeneration apply the corrected datum to existing owned drilling. Loading the update does not alter model geometry.

## 2.9.34 — Remove shelf-pin drilling after deleting shelves

- Extend Refresh drilling to remove positively owned orphan shelf-pin circles within selected cabinets, including cabinets with no live shelf sources.
- Add click-to-clean preview for orphan-only cabinets; cache hover scans without background observers.
- Resolve ownership within each nearest cabinet assembly, isolate shared occurrences, retain hidden/renamed sources and manual/unmarked drilling, and reject locked operations before mutation.
- Keep cleanup and regeneration within the existing single Undo operation.

## 2.9.33 — TANDEMBOX front and runner drilling

- Add insertion/adoption for the supplied TANDEMBOX M/D 500 mm screw-on pilot/gallery pattern, using the front as source for both cabinet-side runner rows. Match all 34 reference circles.
- Compute bottom overlay from adjacent cabinet bases/shelves, excluding drawer bottoms; provide manual override and stored/recognized M/D variants.
- Add Drawers to central EN/PL settings, per-front ownership, Alt removal and Ctrl update. Extend Refresh drilling and Existing drilling adoption/parameter editing. Isolate copies and validate surfaces/depth/clearance before changes.
- Preserve hardware and drawer-part geometry; no MERIVOBOX or unverified lengths.

## 2.9.32 — Refresh icon at startup

- Assign both Refresh drilling icon sizes before registering the toolbar/menu command on first load. Retain idempotent command reload and the 2.9.31 toolbar order. No drilling behaviour changes.

## 2.9.31 — Toolbar order

- Keep Click Front, Profile Library and Order List first, then a separator. Follow with Hinge Drilling, Shelf Pin Rows, Dowels and Screws, Hanger Cutouts and Refresh drilling. Add a final separator before Default settings. Restart SketchUp to rebuild the toolbar.
- No geometry, drilling or handle behaviour changes.

## 2.9.30 — Refresh drilling for all supported operations

- Rename the toolbar/menu command to Refresh drilling and replace its icon with circular refresh arrows.
- Discover associated sources throughout selected cabinets, including fronts. Refresh shelf pins, dowels/screws, hinges and Kamar routing; support multiple operation types on a source.
- Preflight all destinations, retain one-Undo transaction and copy isolation, repair missing Kamar contours while retaining valid routing geometry. Keep per-tool Ctrl refresh scoped to its own type.

## 2.9.29 — Adopt existing hinges and hanger operations

- Add Hinges to the central Default settings panel, sharing the existing hinge-tool preferences and right-click entry. Validate before writing and preserve hinge defaults for older settings callers.
- Scan front and side hinge circles; infer supported imported Blum associations from actual cup heights, with separate cup/front-fixing/side-plate parameter types. Preserve centres, isolate copies, update tags and support multi-circle imports. Adopted hinges use the existing Alt removal and Ctrl regeneration.
- Recognize and adopt supported Kamar L contours separately from drilling circles; preserve the fixed routing template and retain Alt notch filling.
- Translate new controls into English and Polish. Keep the simplified toolbar and all earlier versions.

## 2.9.28 — Simplified drilling toolbar

- Remove standalone Shelf Pin and Dowel/Screw removal icons from the main toolbar; retain their Extensions menu commands and existing Alt-click shortcuts. No drilling behaviour changes. Restart SketchUp to rebuild the toolbar.

## 2.9.27 — Front and side hinge drilling

- Add a hinge drilling toolbar command: Ø35 cup plus two Ø8 front fixings and paired Ø5 side mounting-plate circles. Match the supplied TOP cabinet’s imported Blum geometry.
- Configurable count, actual front-relative top/bottom offsets, hinge side, cup setback and depths. Equally space intermediate hinges; derive side heights from cup axes rather than cabinet bounds.
- Click adds, Alt removes associated front/side drilling, Ctrl updates. Right-click settings, nested picking, surface/depth validation, copy isolation and one-Undo transactions. Preserve imported holes and reject conflicting depths.
- Retain every earlier version. No animation, automatic observers or hardware insertion.

## 2.9.26 — Shared drilling modifiers

- Shelf-pin and dowel/screw tools: hold Alt to remove, Ctrl to refresh drilling after moving a panel, release to return to the base mode. Red removal and green refresh previews update without mouse movement; repeated keydown does not recompute the preview.
- Use the existing one-Undo refresh transaction, with explicit per-tool ownership when a panel has both pin and joint drilling. Preserve unrelated drilling and source transformations. Require adoption for unassociated imported drilling.
- Continue shelf-pin click mode after selected-panel batch actions, matching the dowel tool. Keep standalone refresh and hanger keyboard behaviour isolated from the shared modifier handlers.

## 2.9.25 — Alt removes and repairs Kamar cutouts

- Hold Alt in the existing hanger tool for red removal preview; release it to resume adding. No extra icon. Consume Alt events to avoid focusing the Windows menu.
- Fill supported notches, remove matching routing contours and clear hanger metadata. Preserve exterior/interior/edge materials, unrelated drilling, shared tag definitions and other cabinet copies.
- Validate shell closure, original volume, merged seams, repeat removal, legacy loops, locks, mirrored/scaled copies and modifier callbacks in native SketchUp tests.

## 2.9.24 — Kamar hanger cutouts

- Add a hanger-cutout toolbar/menu command with a first Kamar preset: 55 × 20 mm through-notches and closed exterior L routing contours, 63 × 31 mm overall.
- Use Blum Operations group names/configured operation tag and exactly Kamar D6.0_DEPTH_8.0 on vector edges. Reuse matching legacy loops rather than duplicating them.
- Validate geometry/locks before editing, preserve unrelated machining/materials, isolate cabinet copies and support one Undo operation. Test fresh and existing notches, shell closure, exact removed volume, repeated use and rotated/mirrored/scaled copies.

## 2.9.23 — Exterior back screws and selected-cabinet click mode

- Add exterior back screw rows only at actual contacting bottom/top rails, retaining inward axis correction, back margins and spacing. No unsupported rows for missing rails or front-only stretchers.
- Include the new rows in drilling scan/adoption, parameter editing, removal and refresh; reapplication clears obsolete rear rows after rails are removed.
- Keep Add/Remove dowels and screws active after selected-cabinet batch processing; clear selection for immediate nested-panel hover and clicks.

## 2.9.22 — Room visibility defaults

- Room now defaults to seven tags: Windows, Walls, Skirting Boards, Room Doors, Floor Plan, Floor and Ceiling. Align standalone toolbar fallback and EN/PL help. Existing saved custom assignments are preserved.

## 2.9.21 — Back cutouts and startup preference recovery

- Store central tag/visibility JSON as Base64 to avoid SketchUp string-evaluation SyntaxError after restart.
- Recover existing legacy values without evaluating their text, preserve old keys, and safely fall back on invalid settings.

- Respect actual back end faces and hanger cutouts. Measure end margins from available material, distribute each side independently, and validate full screw cross-sections in world units.

## 2.9.20 — Click to update drilling and grouped import recognition

- Add a refresh-arrow command to remove old owned drilling and regenerate it at the current source-panel position, for shelf pins, rails/fixed shelves and backs. Selection and click modes share one Undo transaction; no background observer is added. Validate the new layout first and isolate shared cabinet copies.
- Recognize multiple complete circles stored in one imported vector container. Adopt selected circles separately while preserving physical size/centre and unrelated circles. This restores recognition of grouped bottom-panel dowels and screws.
- Automatically centre back screw axes within the actual back thickness, including recessed backs, instead of using the previous fixed side-rear offset. Update both settings dialogs to show the automatic behaviour.

## 2.9.19 — Orbit performance fix

- Fix repeated full-model traversal from Room toolbar validation during camera movement. Cache matching groups per model and configured name list, and traverse shared definitions once.
- Invalidate on model commit, Undo, Redo, abort and explicit settings refresh; retain live visibility checks against cached groups. Include ELFIS Tags 1.04.
- Native regression: 1000 repeated validations trigger no additional hierarchy scans. No geometry or user settings are changed by the fix.

## 2.9.18 — Central defaults and existing drilling conversion

- Add a bilingual five-tab settings panel and gear command: shelf pins, dowels/screws, existing drilling, panel tags and visibility. No door settings are moved into this panel.
- Configure multiple comma-separated source/receiver tag aliases; retain existing tool preferences and validate all sections before saving.
- Recognize supported imported circular vector containers, review their source associations, adopt ownership and optionally change diameter/depth while preserving physical centres. Isolate shared copies, reject stale/ambiguous/locked input and support subsequent removal and Undo.
- Include ELFIS Tags toolbar 1.03; configure each button's target tags or named groups. Room now uses named room groups; other existing assignments are preserved. Ignore deleted layer callbacks during rollback.

## 2.9.17 — Joinery removal and descriptive PDF filenames

- Add a separate red-X toolbar/menu command to remove carcass dowel-and-screw vector groups by source-panel click or selection. Preview the associated groups in red; retain imported machining and shelf supports.
- Resolve ownership after source movement, isolate populated cabinet copies, reject locked or ambiguous paths before mutation, and make repeated removal harmless. One operation per application supports Undo.
- Suggest Project_Doors_YYYY-MM-DD.pdf in the complete-order save dialog, or Doors_YYYY-MM-DD.pdf for an untitled model. Sanitize filename characters, preserve Unicode and allow user editing. PDF contents/layout are unchanged.

## 2.9.16 — Carcass dowels and screws

- Add a separate toolbar command for side-panel drilling at rails, fixed shelves and backs. Click a source panel, select several source panels, or select a cabinet to process recognised structural rails/fixed shelves and its back. Adjustable shelves are excluded from cabinet batches.
- Use the inspected 21-spindle sample: 32 mm pitch, first spindle 30 mm from the side front, five Ø8 × 14 mm dowels and five Ø3 × 18 mm screws on a full rail. Short rails crop the same positions without moving the front datum. Unobserved spindles 15–21 start disabled and can be configured.
- Preserve the confirmed 0.2 mm inward axis correction for bottom/top rails; fixed shelves follow the bottom-rail direction. Back panels use screws only, equal spacing, 55 mm end margins and maximum 220 mm spacing by default; the axis is 12.5 mm from the side rear edge.
- Right-click settings show all 21 spindle assignments (D/S/off), diameters, depths, offsets and the exact generated drilling tags, in English and Polish.
- Every vector is a separate named group inside its receiving side panel; group tag Blum Operations, circle tag D8.0_DEPTH14.0 or D3.0_DEPTH18.0 by default. No edge drilling or solid subtraction is added. Imported vectors remain untouched; matching existing vectors are reused.
- Validate receiving faces, cutouts, depth and locked paths before applying. Isolate shared cabinet/panel definitions, preserve physical circle sizes under mirrored/nonuniform scale, and update owned groups without multiplication. Each application is one Undo operation.

## 2.9.15 — Manufacturer follows the door profile

- Remove the manual Manufacturer / source field and Assign to selected items button from both order-list languages, including their JavaScript handlers and Ruby dialog action.
- Keep the source column and manufacturer/source filter. Generated fronts use the selected library profile's manufacturer ahead of old occurrence-level overrides; stored front metadata is a fallback when the profile is unavailable.
- External Facade/Finishing items retain their existing source metadata. No geometry, colours or model attributes are rewritten by this change.

## 2.9.14 — Shared plinth offcuts across widths

- Combine different plinth widths/heights in one lengthwise cutting plan by default. Use the widest part as the stock purchasing width; retain actual part widths in the expanded tree, clipboard and PDF.
- Add a remembered Separate stock widths checkbox to restore independent width plans. Changing it recalculates immediately.
- Keep different products, suppliers, colours and board thicknesses separate in both modes. No two-dimensional nesting or joining of short remnants.

## 2.9.13 — Order groups, stock-length planning and portrait PDF

- Escape clears order-list highlights and selected rows in the HTML window or viewport. A temporary preview tool receives viewport Escape and restores the previous tool; switching tools clears the preview too.
- Numeric ascending/descending dimension sorting, remembered between sessions. Shift selection follows the displayed order. Quantities appear bold before dimensions, including handles.
- Split Finishing into Plinths, End Panels, Pelmets, Crowns and Other, based on tags and their parent folders. Preserve product groups in clipboard and PDF.
- Plinth cutting plans: configurable stock length (default 2400 mm) and saw kerf (default 3 mm), whole-length quantities, expandable per-stock parts, offcuts and cutting loss. Highlight all parts of one stock length or one exact nested occurrence.
- Stock products are identified by their tag (or explicit stock_product attribute); separate tags/products, suppliers, colours and cross-sections are never combined. Instance names can differ. Filters recalculate the visible stock plan; complete PDF uses the whole order.
- Best-fit-decreasing plus bounded exact improvement for up to 32 parts. Mark layouts when the minimum number of lengths has not been proven. Report oversize parts instead of silently splitting or omitting them. No end-trim or mitre allowance is included.
- Print-friendly portrait A4 PDF, bold quantity before combined dimensions, product sections, stock cutting details, wrapped text and repeated headings.

## 2.9.12 — Fix false replacement error after removing audio

- Remove the last obsolete door_operation_finished call from the main click-replacement entry file. It ran after commit, causing Front not replaced / undefined local variable or method even though the front had already been replaced.
- Completion audio remains removed. Door generation, shelf pin tools and existing material/machining behaviour are unchanged.

## 2.9.11 — Remove shelf-pin drilling

- Add a separate red-X Shelf Pins removal icon and Extensions command. Click successive shelves from outside cabinets, or preselect shelves in the current context. Each click/batch is one Undo operation.
- Remove only groups associated with the shelf by ELFIS ownership metadata. Imported/unmarked drilling, other shelves and panel geometry remain intact. Empty removal reports zero without creating a model operation.
- Red preview marks the shelf and associated groups. Removal follows ownership after shelf movement and does not depend on current drilling settings or the shelf still touching both sides.
- Upgrade older PID-based associations before making cabinet copies unique. Stable owner keys preserve remaining shelf associations across cabinet isolation. Isolate parent/side definitions so other cabinet copies retain their drilling. Locked targets are refused.

## 2.9.10 — Immediate shelf tool and tag preview

- Add independent Additional drillings top/bottom counts (0–10), default one each, with the centre hole always present. Grid defaults to 32 mm. Initial front/rear offsets are 57/37 mm; previously saved values remain. No centre-row switch.

- Start Shelf Pin Rows immediately using defaults or saved settings. No startup settings dialog, including selected-shelf batches.
- Open Settings from the active tool's right-click menu. Add an English/Polish settings window with a live drilling-tag preview derived from diameter/depth.
- Preserve entered decimal precision in drilling tag names instead of rounding to one decimal. The group name and circle-edge tag match the preview; the containing group remains on Blum Operations.

## 2.9.9 — Shelf pin rows

- Add a fourth Doors-toolbar icon and Extensions command: Shelf Pin Rows / Podpórki półek. Configure dimensions, then click nested adjustable shelves without entering their cabinets, or preselect several shelf components in the current edit context.
- Find two adjacent vertical Body panels from geometry. For each shelf, create two rows of three vector circles per side, at centre and ±32 mm by default. Default centre is 2.5 mm below shelf underside; diameter 5 mm, blind depth 12 mm, front/rear offsets 37 mm measured from shelf edges.
- Every hole is a separate group inside its side-panel component, tagged Blum Operations. Its circle edges use D5.0_DEPTH12.0 (or the selected diameter/depth). No faces or solid subtraction. Match the inspected model convention, without editing OpenCutList.
- Keep existing row positions, enabled by default, reuses matching two-row positions already present at the shelf support height on both sides. Other settings remain explicit. Existing matching production circles are skipped; ELFIS-owned circles are refreshed on reapply.
- Support rotated/mirrored orthogonal instances and nonuniform scaling with physical dimensions. Isolate shared cabinet/side definitions before inserting vectors. A click or batch is one Undo operation. Refuse locked, ambiguous or unsupported parts and holes outside a panel or deeper than its thickness.
- Adjustable horizontal rectangular boards on Body only. Exclude named Fixed shelf, cabinet base/top and cross members. Fixed shelves, dowels and screws are deferred. No automatic observer after moving a shelf: reapply to refresh ELFIS-owned holes; imported machining is preserved.

## 2.9.8 — Remove completion audio

- Remove completion playback and both sound controls at the user's request after native playback was not reliably audible. Door operations no longer schedule audio or call audio APIs.
- Retain the 2.9.7 print-friendly PDF, styled order-language selector and unchanged SVG previews.

## 2.9.7 — Print-friendly orders and completion-sound preview

- Use white pages, black text and thin grey table rules in the complete-order PDF. Remove solid header backgrounds and alternating row fills. Keep separate Doors, Finishing and Handles sections, pagination and all order data.
- Style the Door Order List language selector consistently with its other controls.
- Replace the quiet 0.14-second completion cue with a clearer 0.38-second two-tone WAV, defer playback briefly after successful operations, and add Test sound / Testuj dźwięk beside the existing preference. The test button does not change the preference. Audio failure cannot undo a door operation.
- Preserve SVG profile/section previews unchanged. Actual audibility depends on the active Windows output and SketchUp application volume.

## 2.9.6 — Finishing orders and dimension labels

- Rename the End Panels order section to Finishing in English/Polish windows, clipboard and complete-order PDF. Include tags anywhere beneath Finishing or Finishing Parts folders, including nested and numbered folders (for example 02 Finishing Parts). Retain support for the standalone endpanels tag.
- Keep finishing products separate from door-profile replacement. The Type column uses the product tag (plinths, pelmets, crowns, end panels, etc.). No profile import is required. Existing manufacturer/source assignment, filtering, consolidation and highlight actions still apply.
- Add Dimensions in model / Wymiary w modelu to the order list. Selected rows show height × width in millimetres on each highlighted occurrence. Preference is remembered. Labels follow nested instance paths, do not change model geometry, skip off-screen/overlapping positions and limit drawing to 200 labels.
- Correct order-list height/width/thickness identification for generated doors with native OpenCutList axes or swapped axes, using physical size and world orientation.
- Keep 2.9.5 native OpenCutList grain compatibility and omit the experimental colour configurator. Native docked custom trays are not part of this update.

## 2.9.5 — Native OpenCutList grain rotation

- Based on 2.9.4, without the experimental colour configurator or finish library.
- Place generated visible geometry directly inside the front component and use native board axes: X/Y span the face and Z is thickness. OpenCutList can rotate inherited grain using Swap length–width, rather than rotating axes around a nested body whose texture stays fixed.
- Whole-door texture orientation also applies to Five-Piece, as requested. Visible joints remain; individual frame-part groups are replaced by direct faces/edges carrying original part names in ElfisDoorPart attributes. This version does not provide separate frame-part cut-list items.
- Slab main material belongs to the component. Broad/chamfer faces inherit it; independent narrow-edge materials remain on faces. CNC and handle containers remain separate with model-space placement preserved.
- Retain geometry-only bounds and order colour detection after native axis changes. Keep independent cache templates when body groups are exploded.
- Existing fronts keep their saved structure until replaced again. Reapply the profile once, then use OpenCutList to assign material and orient grain. No changes to OpenCutList code, material images or automatic grain observers.

## 2.9.4 — Completion sound and optional Slab chamfer

- A short completion sound follows successful door creation/replacement. Batch replacement sounds once after commit; validation failures and cancellation remain silent.
- Toggle Completion sound in the profile-library header. The preference is remembered separately from profiles and is enabled by default.
- Slab profiles can enable a front-edge 45° chamfer with an editable size (suggested 1.5 mm). It is off by default, including for existing profiles.
- Retain overall dimensions, rear plane and individual ABS edge materials. Bevel faces use the front material. Chamfer size is included in geometry caching and order/PDF descriptions.

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

Plinth stock cross-sections are grouped at 0.1 mm nominal precision to ignore tiny import differences (e.g. 150 and 150.01 mm). Cutting lengths retain their measured precision.
