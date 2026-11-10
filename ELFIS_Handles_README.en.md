# ELFIS Handles 1.0.0-beta

> **BETA — Standard handles are not working properly. Use on test models only and verify every placement. This version is not recommended for production use.**

An optional handle module for **ELFIS Door Studio 2.9.1**, with its own toolbar icon and installer. This is a first public test version. It uses Door Studio's front measurement and replacement routines; it is not a standalone extension.

[Download ELFIS Handles 1.0.0-beta](https://github.com/elfis/ELFIS-Door-Studio/raw/refs/heads/main/public/handles/1.0.0-beta/ELFIS_Handles_1.0.0-beta.rbz) · [Polska instrukcja](ELFIS_Handles_README.md)

## Install

Install Door Studio first. In SketchUp, choose **Extensions → Extension Manager → Install Extension**, select `ELFIS_Handles_1.0.0-beta.rbz`, and restart SketchUp. Enable **View → Toolbars → ELFIS — Handles** if necessary. The same command is available in the Extensions menu.

## Import a handle

1. Open **ELFIS — Handles**, then click **Add .skp**.
2. Select your own handle model, prepared at its actual physical size.
3. Enter its name, type (`standard`, `knob` or `edge`), fixing pitch in mm, length, finish, supplier and product code.
4. Choose a position, orientation and offset, then click **Click fronts in model**.
5. Click front components, including components nested inside cabinets. Clicking an equipped front replaces its handle.

The library starts empty. Imported handles appear in the **Handle model dropdown**; this version does not have a thumbnail gallery. No manufacturer models are bundled.

## Component axes

![Component mounting axes for a standard handle and rear-fixed edge pull](docs/handles/handle-axes.svg)

Save each prepared component as a separate SKP using the component's **Save As** command. Its file origin and axes must be the intended mounting frame.

- **Standard handle:** origin at one fixing screw, on the contact surface of the front. Local red X points to the second screw; local blue Z points outward from the front. Green Y follows SketchUp's right-handed coordinate system.
- **Knob:** origin at the fixing screw on the contact surface; pitch is zero.
- **Edge pull:** prepare for top-edge mounting. Origin is halfway along the pull at the intersection of the front's rear surface and top edge. Green Y points upward; blue Z points forward. Red X runs along the pull, completing the right-handed frame. The pull's physical cross-section must fit the door thickness; importing it does not reshape it.

## Position and offsets

Standard handles have eight positions and horizontal or vertical orientation. Corner offsets are measured from the adjacent edges to the nearest fixing screw. Centre positions account for half the pitch.

**Auto** uses half the cross-section width of recognised ELFIS framed fronts. Slab fronts, drawer variants and unknown frames use the configured offset, initially **45 mm**. **Custom** always uses the entered offset.

Edge pulls default to the centre of the top edge. Left/right mounting uses the distance from the door's top edge to the end of the pull. Top/bottom mounting has a separate shift right from centre. Rear-fixing placement uses the door's rear plane.

While clicking edge pulls: **Ctrl → right**, **Alt → left**, **Shift → bottom**. Without a modifier, the position selected in the window applies. A held modifier overrides preservation of an existing position. These shortcuts do not change the existing J-Pull door tool.

## Replace and order

- **Preserve existing front position and offsets** keeps each front's saved placement rules when changing models. Disable it to apply the current settings instead.
- **Apply to selected fronts** works on selected front components. For a selected cabinet, it finds nested fronts already fitted with handles.
- **Replace all existing handles** replaces handles added by this module throughout the model, including hidden occurrences. Exit the current group first. Unmarked, manually placed handles are not replaced.
- Each placement or batch replacement is one undo operation. Shared cabinet instances are isolated when editing one occurrence. Locked objects stop the operation.
- Changing a door style through ELFIS retains and re-seats the handle for the new thickness. Invalid fixing positions or a pull that cannot fit cause the replacement to roll back.
- The module's separate **Handle order list** consolidates models and finishes, counts nested occurrences, and copies a table including supplier and product code. Use **Refresh** after model edits. The existing door order table is unchanged.

## Library storage

`%APPDATA%\ELFIS\HandleLibrary\handles.json` stores product information and settings. The adjacent `models` folder stores copied SKP files. Back up the entire `HandleLibrary` directory. Removing an entry from the library leaves existing placed handles in the model.

## Limits and validation

This version does not create drilling operations. It targets rectangular front components, not arbitrary groups. Unknown frame widths cannot be inferred automatically. For an ordinary front, first click its actual front face so its outward direction can be identified.

Manually scaling a front also scales its nested handle. Reapplying the tool restores the handle's actual size; there is no automatic geometry-change observer in this version.

27 native checks passed in **SketchUp Pro 2026 on Windows**, using synthetic handle and cabinet fixtures. These covered screw offsets, pitch changes, edge mounting, copied cabinets, batch replacement, thickness changes, scaling/mirroring and order quantities. Imported production models still require an axes and fit check. Other SketchUp versions and macOS have not been verified.

## License and support

Part of ELFIS Door Studio, distributed under the repository's [MIT License](LICENSE). Rights to any imported third-party models remain with their respective owners.

Optional [Ko-fi donations](https://ko-fi.com/elfis1920) support AI credits used for development and testing.
