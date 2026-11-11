# Roadmap / Plan rozwoju

The items below are **planned**, not implemented features or promised delivery dates. The current-function inventory is in USER_GUIDE.en.md and USER_GUIDE.pl.md.

## Next: hardware-handle order list / Lista uchwytów

- Identify existing handle components through explicit metadata and/or a configurable tag; avoid requiring users to import a geometry profile.
- Record manufacturer, model/name, product code, finish/colour, hole spacing and quantity when supplied.
- Consolidate identical products into a separate Handles sublist in the order window.
- Click to highlight all occurrences; double-click to zoom; copy the filtered handle list.
- Mark unrecognised/missing product information for review instead of inferring a purchasable product from geometry alone.
- Do not count the integrated J-pull recess as a separate purchased handle. Handle-side information already exists for J-pull doors.

Proposed workflow: select a handle component, mark it as a handle product, enter its order details once, then count occurrences in the model. The final recognition rule/tag name remains to be chosen; no new tag is assumed in the current release.

## Next: PDF order export / Eksport zamówienia PDF

- Export the currently filtered list, with separate Fronts / End Panels / future Handles sections.
- Project title, issue date, dimensions and units, quantities, profile/product, manufacturer and finish names.
- Colour swatches alongside text colour/material names.
- Include review flags and skipped-item warnings; make the scope (visible filtered rows versus selected rows) explicit.
- Stable multi-page tables with repeated headers and readable print layout.
- Keep clipboard copying as the quick alternative.

## Public-release preparation / Wydanie publiczne

- Verify installation/update/uninstall and language persistence on a clean SketchUp 2026 Windows profile.
- Review translation completeness, long-label layouts, screenshots and keyboard navigation with external testers.
- Publish the supported environment and known limitations; test additional SketchUp versions/macOS before claiming support.
- Decide the public licence, distribution channel, support contact and permissions for bundled product-specific profile assets.
- Provide a small neutral sample model and section files, separate from private project models and personal libraries.
- Register release metadata with SketchUp's extension system and complete signing/distribution requirements for the chosen channel before a public store submission.

## Later candidates / Późniejsze propozycje

- Profile-library import/export and manufacturer packs, with explicit version/compatibility handling.
- More ordered product sublists: plinths, pelmets, crowns and other accessories. Currently only Fronts and End Panels are implemented.
- Product-specific drawing variants, richer T&G/panel metadata, more automated catalogue rules.
- Additional machining/CNC integration and cutter-radius treatment, tested independently from visual geometry generation.

## Already completed in 2.9.0

- English default, selectable Polish, persisted preference.
- English and Polish user instructions, controls/shortcuts and current features.
- Version history from the original numbered packages; preserved previous archives.
- In-app documentation entry and a separate list of future work.
