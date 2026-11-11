# ELFIS Door Profile Library — User Guide

Applies to 2.9.1. Dimensions are in millimetres; examples use **height × width**, such as **715 × 596**.

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

PDF export, a separate hardware-handle list, and general accessory ordering beyond End Panels are not implemented. See ROADMAP.md.


## Handles in the order window

The door order window now includes a separate **Handles** section for models placed by ELFIS Handles. **Refresh list** updates both sections, **Copy visible list** copies visible front/panel rows plus the complete enabled handle table, and **Copy handles** copies only hardware. Front profile/colour/source filters affect fronts and panels only; the hidden-elements option also applies to handles. Handles are consolidated by product and finish, including occurrences in nested cabinet copies. The source handle library is not required. Unmarked manual handles are excluded.
