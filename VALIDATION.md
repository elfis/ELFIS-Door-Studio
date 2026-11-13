# Validation notes

## Doors 2.9.14

- Standalone Ruby 3.2.4 tests run the actual stock planning code without connecting to SketchUp: the supplied mixed-width example needs six lengths by default versus seven with widths separated. Occurrences, kerf and waste are conserved; products/materials/thicknesses remain distinct.
- All shipped Ruby syntax compiles under Ruby 3.2.4. EN/PL browser checks cover checkbox persistence/callbacks, shared offcuts and both part dimensions. Existing 2.9.13 browser regressions also pass against the new HTML.
- Mixed/split portrait PDFs rendered and visually reviewed.
- **Follow-up live check passed in SketchUp 2026:** the installed 2.9.14 calculator returned six shared lengths and seven separate lengths; the order window opened and displayed the new checkbox with six lengths in the current project. Earlier 2.9.13 checks remain separately identified.
- Results: public/2.9.14/VALIDATION.json.
- For standalone tests on Windows: `npm install --prefix tmp/ruby-order-tests @ruby/wasm-wasi@2.10.1 @ruby/3.2-wasm-wasi@2.10.1`, then `node test_orders_2914_runtime.cjs` and `node test_orders_2914_ui.cjs`. The Ruby adapter reads supplied source/system fonts and redirects generated fixtures/PDFs into local output files; it does not access the running SketchUp process.

## Doors 2.9.13

- 30 passing native checks in SketchUp 2026: Ruby compilation, kerf/material balance, exact/oversize cases, 60 random small layouts checked against an independent exhaustive solver, tag/product/finish separation, nominal section precision, exact-occurrence highlighting and viewport Escape restoration.
- A 1000-part planning check completed in approximately 0.13 seconds on the development machine; this is an example, not a timing guarantee.
- EN/PL browser checks: numeric sorting, Shift ranges, bold quantity placement, product sections, stock expansion, occurrence/group highlight requests, queued Escape, filtered-stock requests and settings.
- Portrait A4 PDFs rendered and visually reviewed, including Polish labels and a 70-row pagination stress sample.
- Installed files verified by SHA-256; installed order window and Escape checked in an open SketchUp 2026 project.
- Results: public/2.9.13/VALIDATION.json. Run test_orders_2913_native.rb in SketchUp from the repository directory, then node test_orders_2913_ui.cjs. These tests create temporary geometry in an aborted operation and output local fixtures/PDFs; do not commit those output files.

## Earlier checks (corresponding older releases)

Target: **SketchUp Pro 2026 on Windows**. These are development checks, not certification for every model or platform.

- 46 native handle checks: fixing offsets/pitch, calibration transforms, standard tap controls, unchanged edge-pull shortcuts, copied cabinets, batching, re-seating after thickness changes, scaling/mirroring and order quantities.
- 4 calibration start/cancel checks with an imported model.
- 12 native combined-order checks: shared nested counts, hidden elements/tags, finish separation, malformed records, optional handle table and clipboard export.
- 13 native removal/Slab/PDF checks plus 3 PDF Save As/cancel/overwrite checks.
- Slab transfer additionally passed on temporary copies of 38 original model definitions using an existing OpenCutList ABS edge-band material. Original project geometry was not modified by that check.
- Browser checks passed for English/Polish, live handle controls, the red X, narrow layouts, order-table ranges/Ctrl selection, filters, End Panels and copy actions.
- All pages of a six-page Polish stress PDF and a five-page model order were rendered and visually reviewed; Unicode extraction and page numbering were checked.

No private project model, exported project PDF or personal handle library is included here. MacOS, other SketchUp versions, arbitrary source geometry and every manufacturer handle model remain unverified.
