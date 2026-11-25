# ELFIS Handles 1.1.7-beta

**BETA — Calibrate standard handles before use and check placement on a test front.**

Remove ELFIS handles by clicking front components. Tap Ctrl to switch horizontal top centre / vertical top right; tap Shift for horizontal top/bottom or vertical right/left. Positions stay after key release. Live settings, independent offsets and fixing-point calibration. Edge-pull mounting rules are unchanged.

Requires ELFIS Door Studio 2.9.1. Install the RBZ through SketchUp Extension Manager, then restart SketchUp.

[English guide](../../../ELFIS_Handles_README.en.md) · [Polska instrukcja](../../../ELFIS_Handles_README.md)

## 1.1.7-beta — Automatic handle length

Import fills Length from the SKP geometry. Before standard-handle calibration this is a provisional longest file-axis span; calibration recomputes the total length along the fixing-screw axis. Nested group/component transforms and mirroring are included, while construction points are ignored. Edge pulls use their mounting X axis, knobs use their maximum in-plane span.

Edit displays the measured value as `Auto: …` and fills it for automatic/legacy records. Save to accept it. A manually changed length is retained through later calibration; enter the displayed Auto value to return to automatic length. Screw pitch remains separate and comes from fixing-point calibration. Existing mounted instances keep their stored order data until reapplied/replaced.

The same Handles Library layout and the three Handle Tools buttons are retained. Tested in SketchUp Pro 2026 Windows. Previous installers are preserved.
