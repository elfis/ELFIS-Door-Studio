# ELFIS Door Profile Library — User Guide

Applies to 2.9.39. Dimensions are in millimetres; examples use **height × width**, such as **715 × 596**.

## Start here

Open the profile library, select a profile card, then either enter height and width and choose **Create by dimensions**, or choose **Select and click fronts** and click the exterior face of an existing front. New geometry is a door component. Creation places it at the origin of the current editing context. Replacement preserves the existing width, height and back plane; thickness comes from the selected profile.

You can restyle existing generated fronts repeatedly, for example Slab → Five-Piece → J-pull → One-Piece. Click the door component from outside the cabinet; you do not normally need to open nested cabinet groups. The replacement tool targets components, not an arbitrary group. Grouped Facade fronts can also be handled by the order-list batch workflow when their panel geometry is recognised.

When replacement is performed from outside shared cabinets, copies along the clicked path are isolated so other cabinet occurrences are not restyled. If already editing a shared cabinet, leave its editing context or make it unique first. Point to the front's broad exterior face, not the cabinet body.

## Language

The header of both main windows contains **Language / Język → English / Polski**. English is the default, including on an existing installation without a saved language preference. The setting persists between SketchUp sessions.

Changing language reopens that window and clears its row selection/highlight. Unsaved profile edits require confirmation before being discarded. Another already-open ELFIS window retains its inputs and changes language the next time it is opened. Native command labels and tooltips update; the naming submenu has a bilingual title. Profile names, tags, manufacturers, materials and user component names remain data, not translations.

## Profile library controls

| Control | Purpose |
| --- | --- |
| Search profiles | Filter cards by saved name. |
| Star on a card | Add/remove a favourite. |
| Favourites | Show only favourites. |
| Profile card | Set the active profile used by the quick replacement tool. |
| Red bin | Confirm deletion of a custom profile or hiding of a built-in profile. Existing doors remain unchanged. |
| Restore built-in profiles | Restore hidden bundled profiles. |
| Add Five-Piece Door | Import the selected rail cross-section. |
| Add One-Piece Door | Import the selected integral-border cross-section. |
| Add Slab | Create a plain-panel profile using thickness; no section selection required. |
| Add J-pull | Configure a parametric handle recess or load a custom full side section. |
| Save settings as a profile | Persist edits; editing a built-in saves a custom copy. |
| Cancel new profile | Discard the current unsaved new-profile draft. |
| Variant | Choose Automatic, Framed or Low drawer for creation/replacement. |
| Select and click fronts | Activate replacement using the chosen saved profile and variant. |
| Create by dimensions | Build a new door with the entered height and width. |

Save profile edits before creating/replacing doors. Delete controls are disabled while settings are unsaved. At least one available profile must remain. The card door drawing is schematic; the section preview represents stored geometry.

## Four construction types

### Five-Piece Door

Four frame members and an optional separate panel. Broad flat shoulders meet at 90°; the inner decorative moulding and panel groove remain around the opening. The model does not generate tenons, dowels or glue joints.

Draw or import **one closed planar cross-section** at its real size. Select its face, closed outline or a group containing that single section, then click Add Five-Piece Door. A finished extruded rail is not a section. The section must have a recognisable long straight edge for orientation.

Enter a name, manufacturer/source, flat shoulder width, panel thickness and clearance. The shoulder runs from the outer edge to the start of the inner moulding; Bastille uses 75.5 mm. The panel needs a recognised rectangular groove and must be thinner than its opening. Set panel thickness to 0 for a frame without a panel. Overall height and width must exceed twice the section width, in addition to any family limits.

### One-Piece Door

A single front with an integral moulded border and continuous centre. It is a construction description, not a claim that the material is solid timber.

The sample section is 70 mm wide, so a 140 mm-high drawer has no room for the centre between its top and bottom borders. Use a narrower suitable cross-section, a Slab, or a configured low-drawer variant. Values at the size limit are checked with geometric tolerance before creation or replacement.

Import one closed section from the outer edge to the centre, including the flat back. Close the inner end with a vertical edge from the back to the centre surface. This edge defines centre thickness. Do not include a groove for a separate panel. Height and width must exceed twice the section width. Suitable sections can be switched between Five-Piece and One-Piece in the construction field, but a grooved Five-Piece section usually needs redrawing first.

The generator follows the section around a rectangle, fills the centre and produces one solid geometry group inside the door component. Raised centres and segmented curves are supported when the section meets the geometry requirements. Internal corners are sharp; cutter-radius corner relief and CNC toolpaths are not generated. The included demo is not an exact Hartford/Parker product.

### Slab

A plain rectangular solid with square edges. Choose Add Slab, name it, enter thickness and save. No profile section is needed. Thickness must exceed 0.1 mm and be at most 80 mm; width and height must exceed thickness. No edge moulding or handle recess is added.

### J-pull

A panel with a handle recess along the entire selected edge. Choose top, bottom, left or right. The bundled parametric example is not an exact Arena product.

For a parametric profile, set thickness, recess depth from the edge, lip thickness and radius, then save. For an exact custom profile, draw a complete closed side cross-section with the handle at one end and a plain middle. Select it and choose Load selected J-pull cross-section. The section must be longer than twice the moulded/recess zone. Use the front/back and handle-end flip controls to check orientation. Resizing stretches the plain middle while preserving handle details.

The dimension perpendicular to the handle must exceed twice the recess zone. Lip, radius and thickness must be geometrically compatible. A partial-length handle and a combined framed/J-pull generator are not implemented.

## Families and low drawers

A family can include a standard framed door and a different low-drawer front. In **Low drawer variant**, enable height-based selection and choose Plain slab or Custom drawer cross-section. Set minimum/maximum drawer height, minimum width, thickness, and standard frame limits. Save the profile.

For a custom drawer, select a complete bottom-to-top side section with a plain middle and details confined to both end zones. Set the moulded-zone depth, import the section and check the two flip controls. Resizing lengthens the middle without scaling the edge details.

Automatic chooses the variant using the configured height limits. Framed and Low drawer force the requested variant but still validate its limits. Invalid dimensions stop the operation; a failed batch is rolled back. A manufacturer choice does not import a manufacturer's catalogue. Verify family limits against the intended product specification; the bundled Bastille rules are example product-specific data documented in the historical 2.8.0 notes.

## Replacement, materials and machining

The blue outline previews the targeted front. For J-pull, a thicker green line previews the handle edge. Rotation, mirroring and instance scale are accounted for; sheared or invalid panels are rejected. The source panel thickness must exceed 0.1 mm and be at most 80 mm.

Replacement preserves the instance material, tag, visibility/shadow settings and nested machining groups/components. Their contents, attributes and world positions are retained independently of their names. The old generated geometry is replaced rather than accumulated. When an 18 mm source becomes a 22 mm front, the rear plane remains in place and the extra 4 mm extends outward.

This does **not** regenerate holes cut only into old raw panel faces, recalculate drilling depths, generate new machining paths, or guarantee every OpenCutList export. Check production geometry and machining for the actual front. Per-face finishes on the old raw panel are not a substitute for an instance material.

Legacy generated parts from early versions are identified partly by their original part names. Renaming those old internal geometry groups can interfere with restyling. Newer generated geometry carries dedicated attributes.

## Naming

Use **Extensions → ELFIS — Door Naming / Nazwy drzwi**:

| Option | Result |
| --- | --- |
| Keep original door names | Default replacement mode; retain the instance name. A shared definition may require a unique SketchUp definition name. |
| Rename doors | Use the selected saved profile name and height × width, e.g. `Bastille 715x596`. |

New doors created by dimensions always receive a profile-and-size name. A suffix is added only when the component-definition name is occupied. Since 2.4.1, numbering follows SketchUp starting at `#1`, then `#2`; the full size text is retained. This differs from the earlier 2.3.1 custom numbering starting at `#2`. Changing the option does not rename every existing model component.

## Order list

Open the third toolbar button. The list scans the model, including nested cabinet occurrences, and consolidates matching items by profile, construction, current dimensions, materials, manufacturer/source and J-pull handle edge.

ELFIS fronts are recognised through stored plugin attributes, not their component name or tag. **Include fronts tagged Facade ★** adds ordinary front groups/components on the Facade tag. A generated ELFIS front is not counted twice. Non-ELFIS items have a star and need product-type verification.

**Include End Panels** adds a separate sublist. Assign the tag to the whole end-panel group/component. `End Panels`, `endpanels`, case changes, spaces, hyphens and underscores are recognised. No cross-section or door profile is required. The item name identifies a plain or T&G panel. End Panels cannot be replaced with door profiles; a mixed front/panel selection also disables that action. Manufacturer assignment remains available.

| Control | Behaviour |
| --- | --- |
| Refresh list | Read current model geometry and quantities; clear selection/highlight. Refresh after model edits. |
| Include hidden elements | Also include hidden instances and invisible tags. Otherwise they are skipped. |
| Profile / Colour / Manufacturer filters | Combine filters; selection clears when filters change. |
| Clear filters | Reset the three list filters. |
| Single click | Select a row and highlight all its model occurrences. |
| Double-click | Zoom to the row's fronts/panels. |
| Clear highlight | Clear list selection and preview outlines. |
| New profile + Variant + Change profile | Replace all front occurrences in selected rows in one undoable operation. For J-pull, keep each current edge or choose another edge. |
| Manufacturer / source + Assign | Set metadata on selected occurrences without rebuilding geometry. |
| Copy visible list | Copy all filtered rows, not just selected rows, as a tab-separated table. Fronts and End Panels have separate section headings. |
| Copy End Panels | Copy only the filtered End Panels sublist. |

Manufacturer/source choices include ELFIS, Facade, OS Doors, BA, Tade Moldings and a custom name. This is one shared field. The star means non-ELFIS geometry; it does not assert a particular manufacturer.

Generated-door measurements exclude preserved auxiliary containers. Facade fronts use direct panel faces; complex fronts without direct faces may need review. End Panels can contain nested panel solids; vector-only machining groups do not expand their measurement. For ordinary panels, the smallest dimension is treated as thickness and the vertical face axis as height. Unusual axes, horizontal panels and multiple separated solids need manual verification.

Colour includes inherited instance materials. A swatch shows base colour, not a texture image. Orange review markers identify missing/unrecognised information or multiple/no materials. Review warnings before ordering. Highlight is a viewport overlay, not model geometry; it can show hidden items through other objects when those items are included.

## Mouse and keyboard reference

| Context | Input | Result |
| --- | --- | --- |
| Replacement tool | Click | Replace one front; remain in the tool. |
| Replacement tool | Esc | Exit/cancel the tool. |
| J-pull replacement | Shift + click | Handle at bottom. |
| J-pull replacement | Ctrl + click | Handle at left. |
| J-pull replacement | Alt + click | Handle at right. |
| J-pull replacement | No modifier | Saved profile edge. |
| Order list | Click | Select one row; highlight its occurrences. |
| Order list | Shift + click | Select a visible range from the anchor row. |
| Order list | Ctrl + click | Toggle individual rows. |
| Order list | Ctrl + Shift + click | Add a visible range to the selection. |
| Order list | Double-click | Zoom to the selected item. |
| Focused list row | Enter / Space | Select/highlight that row. |
| SketchUp model | Ctrl+Z | Undo creation, one clicked replacement, a whole batch, or supplier assignment. |

J-pull modifiers affect clicked replacement, not Create by dimensions. With multiple modifiers, Shift has priority, followed by Ctrl and Alt. Modifiers have no geometric effect for the other construction types. The same keys in the order dialog select rows; they do not set J-pull orientation there.

## Storage and troubleshooting

User library: `%APPDATA%\ELFIS\DoorProfileLibrary\profiles.json`. It contains saved section geometry, settings, active profile, favourites, hidden built-ins and naming/variant options. Language is stored in SketchUp's ELFIS preferences separately.

| Symptom | Check |
| --- | --- |
| No order rows | Refresh; include Facade if these are ordinary fronts; assign End Panels to the panel container. |
| Front too small | Select a low-drawer variant or a narrower suitable profile; check family height/width limits. |
| Panel does not fit groove | Check groove recognition, panel thickness and clearance; use 0 for no panel. |
| Wrong J-pull side | Check the profile edge, modifier and custom-section flip settings. |
| Shared cabinet warning | Exit the shared editing context or make it unique before replacement. |
| Stale list or geometry changed | Refresh before highlight, zoom, copy or replacement. |
| Profile bin unavailable | Save/discard edits first; the last available profile cannot be deleted. |

Complete PDF export and a separate ELFIS handle table are implemented. General accessory ordering beyond Fronts, End Panels and ELFIS handles remains planned; see ROADMAP.md.


## Handles in the order window

The door order window now includes a separate **Handles** section for models placed by ELFIS Handles. **Refresh list** updates both sections, **Copy visible list** copies visible front/panel rows plus the complete enabled handle table, and **Copy handles** copies only hardware. Front profile/colour/source filters affect fronts and panels only; the hidden-elements option also applies to handles. Handles are consolidated by product and finish, including occurrences in nested cabinet copies. The source handle library is not required. Unmarked manual handles are excluded.


## PDF export and Slab materials

**Export complete order to PDF** in the order-window header saves one portrait A4 PDF with separate Doors/fronts, End panels and Handles sections. Each section starts on a new page; long tables repeat column headings. The export refreshes the model data and includes all sections regardless of table selection, filters or section checkboxes. The hidden-elements and Facade settings still apply. Choose a destination in Save As; cancel leaves files unchanged. The interface language controls the PDF language. Arial is loaded from the Windows system fonts and embedded for selectable Unicode text; no separate PDF software is needed.

When replacing a front with **Slab**, its large-surface materials and each edge material are transferred by surface position. This preserves an existing OpenCutList edge-band material assignment. Previously lost material assignments cannot be reconstructed without an original front or backup.


## Slab chamfer

For Slab profiles, enable Front-edge chamfer, enter the size (suggested 1.5 mm), then save the profile. Existing profiles and new Slabs start with chamfer off. This is a 45° bevel around the front perimeter only; the rear plane and overall dimensions remain fixed. Narrow perpendicular edges retain their individual ABS materials; bevel faces use the front material. Order/PDF type descriptions include the chamfer size.


## OpenCutList grain / 2.9.5

For fronts generated by 2.9.5, apply the board material using OpenCutList, then use its Swap length–width, Swap front–back or Adapt axes tools normally. Existing fronts need to be replaced once to obtain the new geometry structure. Main finish is on the component; Slab edge-band materials stay on narrow faces. Whole-door grain applies to Five-Piece too: visible joints remain but its frame parts are direct faces with part-name attributes, rather than separately grouped cut-list pieces. Handle and machining groups remain separate. The colour configurator is not included.


## Finishing and dimensions / 2.9.6

In Door Order List, Include Finishing gathers items on tags inside Finishing / Finishing Parts and all their subfolders. Numbered folder names such as 02 Finishing Parts are accepted; the old endpanels tag also works outside that folder. Put end panels, plinths, pelmets, crowns and other finishing products on these tags; they do not need door profiles. Their tag appears as Type. Finishing has its own section in the list, clipboard and PDF. Door-profile replacement remains disabled for these items.

Click a row to highlight every consolidated occurrence. With Dimensions in model enabled, each visible highlighted item displays height × width in mm. Turn the checkbox off to keep only the blue outlines. The setting is remembered; refresh or clear highlight removes the labels. Overlapping labels are suppressed and up to 200 labels are shown at once. These are temporary viewport overlays, not permanent SketchUp dimensions or PDF annotations.




### 2.9.8
Completion sound and its controls have been removed. Complete-order PDF uses white backgrounds, black text and thin rules. SVG previews are unchanged.


## Shelf pin rows / 2.9.9

Click the Shelf Pin Rows icon (two cabinet sides with blue dots) and start clicking shelves immediately with defaults or saved settings. Use the active tool’s right-click menu → Shelf pin settings to change diameter, blind depth, shelf-front/rear offsets, centre offset below the shelf underside and vertical spacing. Defaults: Ø5, depth 12, front/rear 37, below 2.5 and spacing ±32 mm. Then click an adjustable shelf from outside the cabinet. Right-click while the tool is active to reopen settings; Esc finishes. To process several shelves in one operation, enter the cabinet, select the shelf components and click the icon.

Keep existing row positions preserves two matching existing row coordinates on both sides at the support height. Turn it off to use your front/rear offsets. Front is inferred from Facade components; without these, front/rear follow the shelf's geometric frame. Equal offsets are independent of that direction. The tool does not create visible hardware: it adds 12 vector-circle groups per shelf inside the two side panels. Group tag: Blum Operations; circle-edge tag: D5.0_DEPTH12.0, adjusted to the selected diameter/depth. Existing identical machining is skipped. Reapplying refreshes only this tool's own groups; it never removes imported drilling.

Use separate rectangular shelf and side components/groups on Body, upright cabinets and orthogonal axes. Locked, sheared, ambiguous or unsupported geometry is rejected. Shared cabinet copies are isolated; when already editing a shared parent, make it unique first. Fixed shelves, bases/tops, dowels and screws are outside this version. Moving a shelf does not automatically update vectors: click it again to refresh ELFIS-owned holes. Imported machining remains untouched. Ctrl+Z undoes the whole click or selected batch. Inspect production vectors before CNC export.


### Shelf settings / 2.9.10
Settings open only from the active tool’s right-click menu. The live Drilling tag / group name preview follows the diameter and depth, including decimals, for example D6.25_DEPTH11.5. Circle edges and group names use that exact tag; the group tag remains Blum Operations. Save remembers settings and updates the active tool; Cancel leaves settings unchanged.

Top and bottom additional hole counts are independent (0–10). One each gives 12 holes per shelf; zero each gives four centre holes. Grid is the vertical spacing. New-install offsets are front 57 mm and rear 37 mm; saved settings remain unchanged. No centre-row switch.


## Remove shelf pins / 2.9.11
Use the new red-X Shelf Pins icon and click an adjustable shelf. Its ELFIS-owned drilling groups are highlighted in red and removed from the side panels; the shelf and cabinet remain. Keep clicking shelves or press Esc. For a batch, preselect shelf components in the current edit context, then click the removal icon. Ctrl+Z undoes the whole click/batch. This removes ELFIS-generated groups only, including their original positions if the shelf has moved. Imported/unmarked vectors are retained, even if they share the same drilling tag. A zero result means no associated ELFIS groups were found. Arbitrarily restructured models or old copies made unique outside ELFIS may lack a recoverable association; unrelated drilling is never guessed from position alone.


## Order list / 2.9.13

Choose Sort by (height, width/length or thickness) and Ascending/Descending. Sorting is numeric within each product group and is remembered. Shift selects a range in the displayed order; Ctrl toggles individual rows. Escape clears selected rows and model highlights, whether focus is in the model or list. Viewport highlighting temporarily activates the order preview tool; Escape restores the previous tool, and switching tools clears the preview.

Finishing is divided by tag/folder names into Plinths, End Panels, Pelmets, Crowns and Other Finishing. Put these tags inside Finishing / Finishing Parts. Keep different stock products on separate tags. The plinth tag identifies the stock product (advanced: override with the stock_product attribute in ElfisBastillePodmien). Colours, suppliers and cross-sections stay separate, regardless of part instance names.

For Plinths set Stock length (default 2400 mm) and Saw kerf (default 3 mm), then Recalculate stock. Whole lengths are the order quantity; expand + for assigned parts, cutting loss and waste. Highlight parts selects all assigned occurrences; clicking one part highlights only that occurrence. Filters recalculate the displayed plan. Parts exceeding stock length are flagged and require different stock, not automatic splicing. No end-trim or mitre allowance is included. The algorithm is bounded for responsiveness; an approximate-layout note means minimum stock count has not been proven.

Complete-order PDF uses portrait A4 with bold quantity before dimensions and separate product sections. It includes stock quantities/cutting layouts and all order items regardless of table filters. Copy visible list includes the filtered product groups and stock layouts. This plans one-dimensional cuts only; it does not generate or move plinth geometry.

Plinth stock cross-sections are grouped at 0.1 mm nominal precision to ignore tiny import differences (e.g. 150 and 150.01 mm). Cutting lengths retain their measured precision.


## Plinth widths / 2.9.14

By default, parts with different plinth widths/heights (e.g. 79 and 150 mm) share the same one-dimensional stock cutting plan. Each product/colour/supplier/board-thickness group uses the widest required section as its purchasing width. Narrower parts can be cut from the lengthwise offcuts of wider stock; every part retains its actual length and width in the tree, clipboard and PDF. This is not two-dimensional nesting and does not join short offcuts to make a long part. Enable Separate stock widths (79 / 150 mm) to calculate each nominal width independently, as in 2.9.13. Changing the checkbox recalculates and remembers the setting. Different materials, colours, products and board thicknesses remain separate in both modes.


## Manufacturer / source / 2.9.16

The order list displays the manufacturer saved in the selected door profile. The source column and filter remain; manual source assignment from the order list has been removed. Existing front metadata is used only as a fallback when the profile/manufacturer is unavailable. External Facade and Finishing items keep their existing source metadata. Refresh the list after editing a profile's manufacturer in the library.


## Carcass dowels and screws (2.9.16)

Use the **Dowels and Screws / Kołki i śruby** toolbar icon. With no selection, click a horizontal rail/fixed shelf on **Body**, or a vertical back on **Back Wall**. Source panels need two adjacent side panels on Body. A back on Back Wall establishes the front/rear direction. Rectangular, upright cabinets can be moved, rotated around the vertical axis, mirrored and scaled; sheared or tilted cabinets are not supported.

Select multiple panels before clicking the icon for a batch. Selecting a cabinet includes recognised Cabinet base/top, cross members and Fixed shelf names plus Back Wall panels. Ordinary adjustable shelves are excluded from that cabinet batch; explicitly clicking/selecting a shelf applies the fixed-joint pattern to it. Only side panels receive vectors. Existing shelf-pin or imported machining is preserved.

Right-click while the tool is active to open settings. Defaults: Ø8 × 14 mm dowels, Ø3 × 18 mm screws, 30 mm datum from the source rail / fixed shelf front, 32 mm pitch, 21 configurable spindle positions. The sample activates S D S – D – S D S – D – S D, with positions 15–21 off. A short rail keeps only fitting positions. The signed centre correction defaults to 0.2 mm inward on bottom/top rails; fixed shelves use the bottom direction. Back screws have equal spacing, 55 mm end margins, maximum spacing 220 mm, and a 12.5 mm rear-edge datum.

Green preview circles are dowels, orange circles are screws. **Esc** ends the tool. One **Ctrl+Z** undoes an application. Vectors are circles without faces, each in its own group inside the side component. The group is on Blum Operations; its name and circle-edge tag contain the diameter/depth. No actual bores are cut and no rail/shelf edge drilling is generated. Repeating an application refreshes owned groups and reuses matching existing circles. Unmarked/imported holes are never removed, so a changed layout can coexist with old imported machining; review those separately before production.


## Remove carcass drilling and PDF names (2.9.18)

Use **Remove Dowels and Screws / Usuń kołki i śruby**, the separate icon with a red X beside the adding tool. Click the source rail, fixed shelf or back, or select several sources before activating it. Red preview circles show only its associated ELFIS joinery groups. Imported machining and Shelf Pins groups stay intact. Moving a source does not lose its association. Shared cabinet copies are isolated; locked/ambiguous associations are rejected before deletion. Repeating removal is harmless. Esc ends the tool; Ctrl+Z restores one removal operation. Removal uses existing associations and does not require current drilling settings or re-detecting panel contacts.

The PDF save dialog suggests **Project_Doors_YYYY-MM-DD.pdf**, using the model/project name and local date. Untitled models use **Doors_YYYY-MM-DD.pdf**. Invalid filename characters are replaced; the suggested name remains editable. The complete order and PDF layout are unchanged.

## Central default settings (2.9.18)

Use the gear button on **ELFIS — Doors**, or **Extensions → ELFIS — Default settings / Ustawienia domyślne**. This panel contains tool defaults, not door/profile settings. Five tabs cover shelf pins, dowels/screws, existing drilling, panel tags and visibility buttons. **Save defaults** affects future operations; **Restore defaults** fills factory values and requires Save to persist. The existing right-click tool dialogs use the same drilling preferences.

**Panel tags:** enter multiple accepted names separated by commas; matching ignores case. Defaults are Body for sides, rails/fixed shelves and adjustable shelves; Back Wall for backs; Facade for fronts. Back tags must be distinct from other panel tags. Choose one operation-container tag (default Blum Operations); each circle retains its diameter/depth tag. Tag changes do not retag existing panels.

**Visibility:** configure each existing ELFIS Tags button as tag names or group names. Room defaults to the tags Windows, Walls, Skirting Boards, Room Doors, Floor Plan, Floor and Ceiling. Custom tag or named-group assignments remain available in the same panel. Other buttons retain their previous tag lists. Missing targets are not created by clicking a button.

**Existing drilling:** select a cabinet/group in the current editing context, open Existing drilling and scan. Review source association and counts, then select rows. Adopt without resizing adds ELFIS ownership; Adopt and update parameters also changes the diameter/depth, circle geometry and machining tag. Enter separate values for dowels, screws (including back screws) and shelf pins. Circle centres remain fixed; other cabinet copies are isolated and one Ctrl+Z undoes the conversion. Subsequent ELFIS removal tools can remove adopted holes by their source panel.

Recognition supports closed circular vector groups/components inside configured receiving side panels, using D…_DEPTH… tags/names and geometric source matching. Ambiguous, locked, elliptical or unsupported groups are skipped. A moved/changed model requires rescanning. Scan within a unique editing context; leave shared cabinet editing first. Merely saving defaults never converts existing holes.

## Update drilling after moving a panel (2.9.20)

Use **ELFIS — Update drilling / Aktualizuj wiercenia** (green refresh-arrow icon). Click a moved adjustable shelf, fixed shelf, rail or back. With selected supported panels/cabinets, the same command processes the selection. It removes the associated old ELFIS vector groups and creates a new layout using current default settings, in one Undo operation. No automatic background refresh is enabled. Invalid new positions are checked before old drilling is removed.

Import first: Existing drilling → Scan → select recognized rows → Adopt. Multiple complete ArcCurve circles inside one vector container are now recognized separately, including bottom-panel dowels and screws. Adoption separates selected circles into individual owned groups, keeping their positions and sizes; unselected circles and other cabinet copies remain untouched. Unsupported polygon-only loops still require review. Adopt before moving the source panel so the association can be determined.

Back screw axes now automatically use the physical centre of the back thickness, including recessed backs. The former fixed side-rear offset is no longer used; end margins and equal-spacing settings remain adjustable.

## Startup settings recovery (2.9.21)

Default tag and visibility settings now use restart-safe storage. Existing values are recovered from SketchUp preferences when the legacy string cannot be read. No model geometry is changed.

## Back hanger cutouts (2.9.21)

Back screws use the actual material intervals on each cut end of the back. The configured end margin is measured from the cutout boundary, independently for each side. The layout stays equally spaced within the maximum spacing. The entire screw cross-section must fit the end face; insufficient material is rejected before modifying drilling. Use Update drilling for existing owned holes.

## Exterior back screws and continued click mode (2.9.23)

Applying back drilling also creates exterior-face screw rows at actual bottom and top rails that meet the back. Front-only stretchers do not qualify. Missing top/bottom rails produce no corresponding row; with neither present only side drilling is made. Rows use the back screw diameter/depth, end margins and maximum spacing. Their height follows the rail thickness centre plus the inward correction (9.2 mm from the outer rail face for an 18 mm rail with 0.2 mm correction). Existing drilling scan, parameter editing, removal and refresh include these owned rows. Reapplying clears obsolete exterior rows after rails are removed.

After processing a selected cabinet, Add/Remove dowels and screws stays in click mode and clears the assembly selection so nested rails and backs can be highlighted immediately.

## Hanger cutouts — Kamar (2.9.24)

Use **ELFIS — Hanger Cutouts / Wycięcia pod zawieszki** (panel with two orange L corners). Click a back panel from outside its editing context, or select back panels/cabinets and run the command. Each back needs two adjacent configured side panels to establish its orientation and exterior face. Esc ends click mode; right-click shows the current Kamar specification.

The initial preset is Kamar: two top-corner through-notches, each **55 mm high × 20 mm wide**. A separate closed six-edge L contour surrounds each notch on the exterior back face. Its overall size is **63 mm high × 31 mm wide**: 8 mm below and 11 mm towards the panel centre. The L pocket is represented by CNC vectors, not a second recessed solid cut. Groups are named **Blum Operations** and use the configured operation-group tag (Blum Operations by default). Every vector edge uses exactly **Kamar D6.0_DEPTH_8.0**. The former group tag Kamar D6.0_DEPTH_18.5 is not applied to new contours.

Correct existing notches are retained. Matching legacy L groups are reused and normalized; repeat applications do not duplicate contours. Different/partial notches, locked targets and insufficient material are rejected before editing. Other cabinet copies, materials and unrelated machining groups are preserved. One Undo reverses an application. The current preset requires a vertical, orthogonal back thicker than 8 mm and sufficient size for both corners. Additional hanger types can be added as separate presets in this module; only Kamar is currently available.

## Remove hanger cutouts with Alt (2.9.25)

Activate the existing Hanger Cutouts icon. **Hold Alt and click a back** to remove its matching Kamar L contours and fill both 55 × 20 mm through-notches. The preview turns red while Alt is held. Release Alt to return immediately to adding. No extra toolbar icon is added.

The repair extends neighbouring face materials over the filled corners and merges redundant coplanar seams. It preserves unrelated drilling and other cabinet copies. Matching legacy Kamar loops are supported too. Repeating removal on an already repaired panel is harmless. The shared Kamar vector tag remains in the model so other cabinets keep their assignments; the matching vector groups are removed only from the targeted back. One Undo reverses the removal and repair.

## Alt / Ctrl in shelf-pin and dowel tools (2.9.26)

The existing **Shelf Pin Rows** and **Dowels and Screws** tools now share momentary modifier controls:

| Action | Result | Preview |
| --- | --- | --- |
| Click | Add drilling with the current settings | Normal colours |
| Hold Alt + click | Remove the clicked source panel's associated drilling | Red |
| Hold Ctrl + click | Remove old associated holes and regenerate at the source's current position | Green |

Release the modifier to return to the tool's base mode. Alt takes priority while both keys are held. The preview changes immediately without moving the pointer. Ctrl changes **drilling positions, not the shelf/panel position**. It uses the existing one-Undo refresh transaction; no automatic background refresh is added. Unassociated imported holes must first be adopted in Existing drilling. A specific tool updates only its own drilling type, even if a source carries both types. Existing separate removal/refresh icons remain usable. Shelf-pin batch processing now leaves click mode active and clears selection, matching the dowel tool. Hanger Alt removal is unchanged.

## Hinge drilling (2.9.27)

Use **ELFIS — Hinge Drilling** in Extensions or its new hinge toolbar icon. Click a front, including through a containing cabinet, to create CNC circles in the front and adjacent cabinet side. This creates drilling vectors, not hinge hardware or animation.

- Click: add. Repeated clicks skip matching existing circles.
- Hold Alt + click: remove the drilling associated by this tool with that front, in both panels. Unassociated imported holes remain unchanged.
- Hold Ctrl + click: replace associated drilling at the front's current position.
- Right-click → **Hinge drilling settings**: count, top/bottom offsets, Auto/Left/Right side and drilling dimensions. Esc exits.

Default reference: Blum layout measured from the supplied TOP cabinet. Front: Ø35, depth 13 mm, cup edge 5 mm (axis 22.5 mm from the front edge); two Ø8 × 13 mm holes, 45 mm apart, 9.5 mm farther inward than the cup axis. Side: two Ø5 × 11.5 mm holes per hinge, 32 mm apart, 37 mm from the actual side front. Default two cup axes are 100 mm from the front's top/bottom; extra hinges divide the interval equally. A 715 mm front beginning 1 mm above a cabinet bottom gives axes at 101 and 616 mm from that cabinet bottom. Depths and offsets are configurable; this is not a universal hinge compatibility calculation.

Auto uses the side of existing Ø35 cups when present, otherwise the closest adjacent cabinet side (left on a tie). Choose Left/Right explicitly for a single full-width door if needed. Each drilling group is inside its receiving component, on the configured operations tag; its circle edges use D…_DEPTH… tags. Front tag and cabinet-side tags follow Default settings. Surface and depth checks reject unsupported holes/cutouts. Other cabinet copies, materials and unrelated drilling are preserved. One operation is undoable with Ctrl+Z. No background observers or auto-refresh are added.

Supported: upright closed fronts and orthogonal cabinet axes, including plan rotation, reflection, scaling and unique open editing contexts. Make a shared open cabinet unique before drilling. Imported coincident holes with different depths require review; Alt never adopts or removes them automatically.

## Simplified drilling toolbar (2.9.28)

The main toolbar no longer has separate Remove Shelf Pins and Remove Dowels and Screws buttons. Use Alt + click in their main tools. The removal commands remain in Extensions. Restart SketchUp after updating to rebuild the toolbar without the old buttons.

## Existing hinge drilling and Kamar operations (2.9.29)

**Default settings → Hinges** now holds the hinge tool's count, opening side, actual front-relative offsets, cup setback, mounting-plate setback and depths. The hinge tool's right-click settings opens this same tab. Save changes defaults only; Ctrl + click on a front regenerates its associated holes with the chosen defaults.

**Existing drilling → Scan selected cabinet** now includes front circles and side mounting-plate holes, with separate Hinge cups / Front hinge fixings / Side hinge plates types. Imported hinge association uses the actual Ø35 cup heights (including non-default top/bottom offsets) and the supported Blum 45/9.5 front-fixing and 32/37 plate layout. A compatible front with at least two cups must be in the scanned assembly for imported plates to be associated. Unknown or ambiguous geometry remains unassociated. Owned ELFIS hinges keep their association after being moved or resized.

Adopt without resizing keeps the imported geometry and associates both receiving panels with the front. Adopt and update parameters edits each selected type's diameter and depth, keeping all centres fixed and updating CNC tags. Complete circular curves bundled in a machining group are separated safely; unrelated circles and other cabinet instances remain unchanged. Adopted hinge groups then work with Alt removal and Ctrl regeneration in the hinge tool. Ctrl regeneration uses current hinge defaults, so set the intended count/offsets before using it on an imported layout.

Recognized Kamar L contours are listed separately as **Kamar · L 31 × 63 · D6 / 8 mm**. They can be adopted only when matching the supported 55 × 20 mm through-notch and exterior routing template. Adoption preserves the contour and marks it for the hanger tool; Alt in that tool removes the contour and fills the notch. Kamar diameter/depth fields are fixed in Existing drilling, and its shape is never converted to a circle. Unsupported hanger types and arbitrary routing contours are not inferred.

## Refresh drilling (2.9.30)

The former Update drilling command is now **ELFIS — Refresh drilling**, with a circular-arrow toolbar icon. Select a cabinet or several source panels and press the icon to refresh all associated shelf-pin rows, dowel/screw holes, front and side hinge holes, and Kamar routing contours. Without a selection, click a source shelf, rail, back or front. A source with multiple operation types refreshes each type. Every destination is validated before removal; one Ctrl+Z undoes the batch and other cabinet copies remain unchanged. Imported operations must first be adopted in Existing drilling.

Circle layouts use the current tool defaults. Existing valid Kamar notches/contours are retained instead of filling and cutting again; missing matching contours are recreated. Unsupported cutouts are rejected. The per-tool Ctrl shortcuts still refresh only their specific drilling type. No background refresh or observers are added.

## Toolbar order (2.9.31)

Click Front → Profile Library → Order List → separator → Hinge Drilling → Shelf Pin Rows → Dowels and Screws → Hanger Cutouts → Refresh drilling → separator → Default settings. Handles retain their separate toolbar. Restart SketchUp after updating to apply the new order.

## TANDEMBOX M/D drilling (2.9.33)

Two workflows: **TANDEMBOX Drilling** inserts or adopts supported holes; **Refresh drilling** updates associated drawer drilling, also throughout a selected cabinet. The new drawer icon follows Hinge Drilling on the main toolbar. Click a front through its cabinet, Alt + click to remove its associated front/side circles, Ctrl + click to regenerate. Right-click opens **Default settings → Drawers**.

This first version supports the supplied **TANDEMBOX M and D, NL 500 mm**, screw-on front brackets with Ø2.5 × 3 mm pilot holes, and D gallery Ø10 × 12 mm. It does not insert hardware, drawer bottoms/backs, or modify their geometry. MERIVOBOX, other runner lengths, and other fixing variants are not inferred.

The actual front back plane anchors the pattern. Fixing lines are 15.5 mm inward from each cabinet side's inner face. Front pilot axes are 49.5/81.5 mm above the bottom datum; D adds gallery axes at 209.5 mm. The datum is front bottom plus the bottom overlay. Runner axes are 35 mm above that datum, with fixing points 19/37/261 mm from the receiving side's front edge. This exactly matches all 34 front/runner circles in the reference cabinet: D, D and M. Circle edges retain diameter/depth CNC tags; groups use the configured operations tag.

**Auto overlay** finds a full-width cabinet base or shelf intersecting the first 80 mm above the front bottom, touching the front back plane; drawer-bottom parts named Drawer/Szuflada are excluded. It uses the closest top surface. The sample lower front starts at 1 mm, its base top is 18 mm, giving 17 mm overlay; the other two fronts have none. Choose **Manual** for unusual inset bases, large overhangs or unsupported assembly arrangements. Front and side circles move together by the overlay amount.

**Auto variant** uses stored M/D metadata or the supported existing pilot/gallery pattern. For an unmarked new front choose M or D explicitly. New source ownership and variant are stored inside the front; matching individual imported circles are adopted without duplication. For multi-circle imported containers use **Existing drilling → Scan → Adopt** first. Existing drilling lists front fixings, gallery fixings and runner fixings separately and can edit their diameter/depth without moving centres. Adopt before manually moving unassociated imported fronts; old unassociated side holes are not guessed or deleted.

Refresh regenerates only associated circles using the current settings. It checks receiving surfaces, depth and cabinet clearance (at least 503 mm for NL 500) before removal. Shared cabinet copies are isolated; locked, ambiguous and unsupported destinations are rejected. One Undo per click/batch; no automatic observers. Upright fronts and orthogonal cabinet axes are required.

## Deleted shelves and Refresh drilling (2.9.34)

After deleting a shelf, select its cabinet and use **Refresh drilling**. This removes the shelf's orphaned ELFIS-owned shelf-pin circles and updates the surviving associated operations in one Undo step. A cabinet with no shelves left can also be cleaned: select it, or activate Refresh drilling and click its side from outside.

Cleanup checks ownership within the nearest cabinet assembly with two parallel side panels. Hidden or renamed source shelves remain valid; copied cabinets are isolated. Locked operations stop the batch before changes. Manual, unmarked or legacy drilling without source ownership is preserved. Selecting only a side panel does not establish that a source shelf has been deleted. No background refresh observer is added.

## Rail and fixed-shelf front datum (2.9.35)

The first spindle offset for dowels and screws is measured from the **source rail or fixed shelf front**, not the receiving side. All following spindle positions stay at 32 mm intervals from that same source. Example: a 31 mm setting and a rail recessed 0.5 mm produce a side-hole axis 31.5 mm from the side front. At 10 mm recess it becomes 41 mm. Short rails omit positions beyond their own depth without moving the datum.

This applies to bottom and top rails and fixed shelves, including rotated/reflected/scaled cabinets. Back screw placement and the 0.2 mm inward thickness correction keep their existing rules. Existing drilling does not move on loading the update: select the cabinet and use **Refresh drilling**, or Ctrl-click its source panel, to regenerate owned holes using current settings. Adopt unowned imported drilling before refreshing it.

## Hinge viewport controls (2.9.36)

Activate **Hinge Drilling** to show the on-screen panel. Hover a front to preview the drilling and read numbered cup-axis positions in millimetres from the front bottom. Move onto the panel to keep that front in preview. Change hinge count with **− / +**, minimum 2, maximum 10; the layout must also fit the front. Top and bottom offsets have 1 mm step buttons. Click a value to enter an exact count or distance. Choose Auto / Left / Right for the hinge side. Intermediate hinges stay evenly spaced.

**Mouse wheel:** over a front or the count control it changes count; over a top/bottom offset control it changes that offset by 1 mm. Away from a front and panel the wheel still zooms. Changes only affect the preview until you **click the front**. Invalid layouts retain the last valid settings. Alt still removes associated drilling; Ctrl still regenerates it. Right-click opens full default settings; Esc exits.

When a quick layout is applied to an already owned front, its associated front/side drilling is replaced, so reducing count or changing sides leaves no obsolete hinge rows. Each front stores its chosen count, offsets and side. Reopening the tool and Refresh drilling preserve this layout; drilling depths still follow current defaults. Quick controls do not change global defaults. Imported unowned drilling must be adopted before it can be safely removed or regenerated. This feature draws tool controls only; no background observer and no dependency on OpenCutList's UI framework.

## Arrange Shelves (2.9.37)

Use **Extensions → ELFIS — Arrange Shelves**, or its shelf-spacing toolbar icon. Click a cabinet, or select one before activating the tool. The viewport panel shows shelf count and every clear opening, numbered **from bottom to top**. Labels stay visible in the model while adjusting the preview. Use +/− (or wheel over the count control), click the count for exact entry, and use **Distribute equal clear openings** to reset the distribution. Changing count resets to equal clear openings.

**Enter openings / ratios** accepts one entry per opening: three shelves need four entries. Commas, semicolons or colons separate entries; use a decimal point for fractional mm. Unqualified numbers below 10 are weights; numbers 10 or above are fixed mm. Append mm for any fixed value, e.g. 5mm. Example **300,200,1,1** fixes the two bottom openings at 300 and 200 mm and divides the remaining space equally. **300,200,3:1** divides the remainder 75% / 25%. Explicit percent values are also weights. All-fixed entries must exactly fill the available height. Every opening must be at least 1 mm.

The height is measured between the upper face of the cabinet base and the lower face of the cabinet top. All actual shelf thicknesses are then deducted before dividing the free space. A 720 mm cabinet with 18 mm rails and three 18 mm shelves has 630 mm available for its four openings: 300,200,1,1 gives **300 / 200 / 65 / 65 mm**. Upright bays without a full top use the side-panel top as the upper limit. Existing shelves keep their actual thickness/depth; added shelves copy the lowest shelf's geometry, tag and component material. Reducing count removes the topmost adjustable shelves. Count can be 0–20; the model retains a template definition to restore shelves after zero. Add a template shelf first in a new empty cabinet; purging unused component definitions can remove that saved template.

**Apply + drilling** moves/adds/removes shelves and regenerates their associated shelf-pin vectors at the new positions using current defaults, without retaining old row positions. One Undo rolls back the batch. Unowned imported support drilling must first be adopted using **Default settings → Existing drilling**. Other machining is preserved. Fixed shelves and rails are excluded; a fixed shelf inside the bay or multiple side partitions require selecting a separate compartment. Locked panels, changed previews and impossible dimensions are rejected. Cabinet copies are isolated. No background observers or automatic recomputation while orbiting.

## Hanger cutouts: independent back panels (2.9.38)

Activate **Hanger Cutouts** and choose **Left / Right / Both** in the viewport panel. Ctrl cycles Both → Left → Right → Both; hold Alt and click to remove the selected corner(s) and fill the cutout(s). Directions are viewed from the exterior of the indicated back. The preview shows exactly which corners are targeted. Activation alone no longer edits selected cabinets.

Each back stores its actual existing corner layout independently. Refresh drilling preserves a two-corner back alongside a one-corner back, including perpendicular backs in corner cabinets. Without saved attributes the supported existing Kamar geometry and matching routing loops supply the layout; Refresh adopts that layout without adding the other corner. Existing supported cutouts can still be removed without attributes. Unrelated drilling and materials are preserved. Each click is one Undo; copied cabinets are isolated. Non-standard or ambiguous cutouts are rejected for review.

This update extends **Kamar hanger cutouts and their Refresh support**. Corner-cabinet shelf arrangement, shelf-pin generation, joinery and corner hinge patterns are separate pending work. The existing fixed Kamar dimensions remain unchanged.

## L-shaped corner cabinets (2.9.39)

The existing **Arrange Shelves**, **Shelf Pin Rows**, **Dowels and Screws**, **Hinge Drilling** and **Refresh drilling** tools now support the inspected upright L cabinet with perpendicular sides and two separate backs. No new toolbar is required.

- **Arrange Shelves:** select the whole corner cabinet. The panel retains the real shelf outline, including a rounded inside corner. Count and opening ratios work as before, measured bottom to top after deducting rail and shelf thicknesses. Top/base panels may extend farther into the opening than adjustable shelves. A 954 mm cabinet with 18 mm rails and three 18 mm shelves gives four 216 mm clear openings; 300,200,1,1 gives 300 / 200 / 182 / 182 mm. Apply moves or clones complete shelf components and regenerates associated drilling atomically. Zero shelves retains the template and its support pattern for restoration.
- **Shelf pins:** receiving boards are found at the actual straight shelf edges, not by assuming two parallel sides. Existing positively associated imported support circles are adopted on the clicked corner shelf (or during Arrange Shelves Apply), so subsequent updates remove their old positions. Custom row offsets are anchored to the shelf-edge ends and retained on added shelves. In the reference cabinet each shelf has twelve side circles and three through-back circles. Through-back rows enter from the exterior and use the actual back thickness, including scaling. They are retained where the imported or saved pattern specifies them; the tool does not invent support rows in the other back. Blind side rows use the configured depth. Pitch, below-shelf axis and extra holes use current settings. Ambiguous/unassociated machining remains untouched.
- **Dowels and screws:** L rails and fixed shelves drill only their actual receiving side panels; spindle positions reference each source edge and retain the configured inward correction. Back panels are resolved independently, including their real butt joints. Back screws respect actual notches; exterior bottom/top screw rows appear only where a rail actually meets that back.
- **Hinges:** both perpendicular fronts use the supported existing Blum cup/fixing/plate pattern with their own receiving side. The viewport count/offset controls and per-front Refresh work independently. Stored hinge side directions now follow the component when mirrored. This is drilling support, not hinge hardware insertion or opening animation; it does not introduce an arbitrary concealed-hinge or folding-door template.
- **Refresh:** updates owned corner operations and removes orphaned shelf support groups from both sides and backs when the source shelf has been deleted. Alt removal remains available in the individual tools. Existing Kamar Left / Right / Both cutout layouts are retained.

Each operation can be undone. Locked geometry, unsupported outlines, skewed panels, ambiguous contacts and holes crossing actual panel edges are rejected. No timers, background observers or automatic refresh during orbiting. Corner arrangement requires a single bay with a consistent adjustable-shelf outline and a shelf template (or a retained saved template); fixed internal divisions require selecting a separate compartment. Unrecognized custom drilling still needs review in Existing drilling.
