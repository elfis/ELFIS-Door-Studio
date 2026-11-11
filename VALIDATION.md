# Validation notes

Target: **SketchUp Pro 2026 on Windows**. These are development checks, not certification for every model or platform.

- 46 native handle checks: fixing offsets/pitch, calibration transforms, standard tap controls, unchanged edge-pull shortcuts, copied cabinets, batching, re-seating after thickness changes, scaling/mirroring and order quantities.
- 4 calibration start/cancel checks with an imported model.
- 12 native combined-order checks: shared nested counts, hidden elements/tags, finish separation, malformed records, optional handle table and clipboard export.
- 13 native removal/Slab/PDF checks plus 3 PDF Save As/cancel/overwrite checks.
- Slab transfer additionally passed on temporary copies of 38 original model definitions using an existing OpenCutList ABS edge-band material. Original project geometry was not modified by that check.
- Browser checks passed for English/Polish, live handle controls, the red X, narrow layouts, order-table ranges/Ctrl selection, filters, End Panels and copy actions.
- All pages of a six-page Polish stress PDF and a five-page model order were rendered and visually reviewed; Unicode extraction and page numbering were checked.

No private project model, exported project PDF or personal handle library is included here. MacOS, other SketchUp versions, arbitrary source geometry and every manufacturer handle model remain unverified.
