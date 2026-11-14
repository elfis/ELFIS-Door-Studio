# Features and controls — Doors 2.9.39 / Handles 1.1.9-beta

**Development status:** New feature development is on hold until **OpenCutList 8.0**. Many planned features depend on or are intended to work with OpenCutList; their design will be reviewed against that release before development resumes. The features documented below are already implemented. No OpenCutList 8.0 compatibility is claimed in advance.

The [README feature inventory](README.md#features) lists every current tool. This page provides its controls and important distinctions. Measurements are millimetres; front dimensions are height × width.

## Fronts and profiles

| Tool / construction | Behaviour |
| --- | --- |
| Click Front | Apply the current profile to a clicked nested front component; continue clicking successive fronts. |
| Profile Library | Create/edit reusable profiles, choose construction/variant, enter dimensions or start click replacement. |
| Five-Piece | Four frame members plus optional panel; square broad shoulders and moulding around the centre. No tenons/glue joints are generated. |
| One-Piece | Integral routed-border front from the stored section; minimum opening limits apply. |
| Slab | Plain panel with thickness and optional front chamfer; retains supported individual edge-band materials. |
| J-Pull | Rear-machined pull; Shift bottom, Ctrl left, Alt right orientation modifiers during placement. |
| Profile families | Link framed/low-drawer variants and use Automatic where configured. A profile must physically fit the front. |
| Naming | Retain original names, or use selected profile and dimensions; add a numeric suffix only when needed for a naming conflict. |

Profile editing includes preview, favourites, deletion with confirmation and restoring built-ins. User profile names, source/manufacturer names and materials are not translated. Replacing a door does not regenerate arbitrary unrecognized imported machining.

## Order List and Finishing

Consolidates identical instances throughout nested assemblies while measuring actual size and material. Optional non-ELFIS Facade items are marked ★. Finishing tags/folders produce separate Plinths, End Panels, Pelmets, Crowns and Other groups. ELFIS handles have a separate table with filters and occurrence highlighting/zooming.

| Action | Result |
| --- | --- |
| Single click | Highlight the row's occurrences. |
| Double click | Zoom to the occurrences. |
| Ctrl-click | Add/remove an individual row. |
| Shift-click | Select a range. |
| Escape | Clear order selection and model highlights. |
| Replace selected fronts | Apply the chosen profile to selected front rows; Finishing items cannot become door profiles. |
| Refresh list | Re-read the model after edits. |
| Copy | Copy the corresponding table to the clipboard. |
| Complete PDF | Refresh and export all order sections to one print-friendly portrait A4 PDF. Table filters/row selection do not limit this complete export; hidden-element/Facade inclusion options still apply. |

Stock plans use actual cutting lengths with editable kerf and stock length. Expand a stock length to inspect or highlight its parts. Different widths share lengthwise remnants by default; Separate stock widths restores separate plans. This is one-dimensional length planning, not sheet nesting or joining short offcuts.

## Cabinet machining

Operations are vector groups assigned to the relevant receiving panel and machining tags. The tools preserve unrelated geometry and isolate supported copied occurrences. In click tools **Alt removes**, **Ctrl regenerates** and **Escape exits**; read the active status/preview before applying. Right-click opens settings where provided.

| Tool | Controls / scope |
| --- | --- |
| Shelf Pin Rows | Diameter/depth, front/rear offsets, 32 mm default pitch and independent extra holes above/below. Ctrl rebuilds at the shelf's current position. |
| Dowels and Screws | 21-spindle pattern with screw/dowel/disabled positions. Datum is the source rail/fixed shelf front; a 0.5 mm recess plus 31 mm offset produces 31.5 mm from the receiving side front. Back screws use real panel contacts and the back's thickness centre. |
| Hinge Drilling | Minimum 2, maximum 10 hinges; top/bottom offsets and Auto/Left/Right side. Viewport +/− or wheel change count; click values for exact input. Wheel over an offset changes it; away from controls/fronts normal zoom remains. Click front to apply preview. Defaults include 100 mm end offsets, Ø35 cup, two Ø8 front fixings, corresponding Ø5 side fixings. |
| Drawer Drilling | Supported TANDEMBOX M/D 500 mm pattern only, referenced to drawer-front placement with automatic or manual bottom overlay. Not general drawer model insertion. |
| Hanger Cutouts | Kamar 55 × 20 mm through cut and exterior L routing; saved Left/Right/Both per back. Ctrl cycles layout; hold Alt to remove the chosen cutout(s) and repair the panel. Recognized old geometry need not already have attributes. |
| Refresh drilling | Update supported owned shelf pins, joints, hinges, drawers and hanger layouts; clean positively owned supports whose shelf was deleted. Select the cabinet(s) or use the supported click preview. One Undo restores the batch. |
| Existing drilling | Scan/adopt supported imported vectors and associate them with source parts. Supported parameter conversion covers shelf pins, joints, hinges, hanger operations and the validated drawer pattern. Unknown or ambiguous operations are not guessed. |
| Default settings | Shelf pins, joints, hinges, drawers, adoption, panel tag roles and visibility configuration. Defaults do not silently change existing holes; explicitly refresh or convert them. |
| Visibility toolbar | Configurable tag lists / named-group rules; Room and cabinet/product roles can be configured separately. |

## Arrange Shelves and L-shaped cabinets

Select/click a cabinet, adjust count in the viewport (0–20), enter clear openings or choose equal openings, then **Apply + drilling**. Count increase clones a template; decrease removes topmost adjustable shelves. Clear openings are calculated bottom-to-top after deducting actual shelf and rail thickness. Zero retains a template for later restoration while its definition remains available.

Unqualified 1–9 values are weights; values from 10 are mm; add `mm` to force a small fixed dimension. Example `300,200,1,1` reserves 300 and 200 mm, then halves the remainder. `3:1` divides the remainder 75% / 25%. Fixed shelves/partitions bound the bay and are not redistributed.

For supported upright L cabinets, previews/clones retain the full outline and rounded corner. Receiving faces are detected at actual perpendicular edges. Recognized imported support layouts are adopted, retaining edge-anchored positions and existing exterior through-back rows at actual back thickness. The tool does not invent rows in another back. Rails, independent back butt-joints, asymmetric Kamar layouts and mirrored hinge sides are supported. Arbitrary skewed or ambiguous assemblies require review.

## Handles — 1.1.9-beta

Toolbar: **Add Handle**, **Remove Handle**, **Handles Library**. Import your own SKP, set product details and calibrate fixing points. Automatic length measurement is separate from fixing pitch. Placement can use clicked fronts, selected fronts or supported replace-all commands. Removing a library entry does not remove already placed handles.

| Standard handle control | Action |
| --- | --- |
| Tap Ctrl | Toggle vertical/horizontal while retaining mounting position. |
| Tap Shift | Mirror left/right. |
| Tap Alt | Mirror top/bottom. |
| Tap Tab | Toggle corner / edge-centre anchoring. |

Edge pulls rotate to match the selected edge. **Side-mounted rear-fixed pulls have specific controls:** signed centre offset (positive up, negative down); Shift cycles centre/up/down using the chosen absolute distance, or 45 mm if zero; Alt switches side while retaining the offset. Ctrl changes mounting axis, Tab changes anchoring. These override the generic Shift/Alt mapping for that mounting case. Preview and insertion use the same calculation.

Auto offsets use half the recognized framed-front section width; Slab/small drawers/unknown frames use configured fallback offsets (45 mm by default). Actual bounds and fixing checks can reject a placement. See the [handle mounting axes and calibration guide](ELFIS_Handles_README.en.md).

## Not implemented / development hold

New features await OpenCutList 8.0. Hinge/drawer animation, collision physics, a plinth geometry maker, general MERIVOBOX/other drawer patterns and the rolled-back V-Ray colour configurator are not current features. Existing hardware models are not supplied. See [validation](VALIDATION.md) before manufacturing.
