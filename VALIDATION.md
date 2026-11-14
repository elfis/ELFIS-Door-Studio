# Validation and limits

Doors **2.9.39**: **248 passing native checks**, including 88 corner-cabinet checks, in SketchUp Pro 2026 on Windows. The installed files were hash-verified against the staged release. No new geometry tests were run solely for this GitHub documentation update.

[Machine-readable release summary](public/2.9.39/VALIDATION.json) lists test counts and limits. Fixtures covered copy isolation, Undo, source-based spindle offsets, shelf arrangement and deletion cleanup, hinge layouts/mirroring, imported drilling adoption, Kamar layouts/removal and Refresh. Two old harnesses depend on absent/changed production-model fixtures and are excluded from the passing count; the current self-contained regressions provide the relevant coverage.

Some native regression scripts expect an inspected reference cabinet in the active model. Read their prerequisites and use disposable model copies. Source packages and SHA-256 files are retained for repeatability. Installer archives are not rewritten by this documentation update; GitHub documentation may contain later clarifications than the archived offline guides.

**Scope:** upright supported rectangular/L single-bay cabinet geometry; recognized or stored support layouts; actual receiving-face validation. Through-back support rows are preserved only when recognized/saved. TANDEMBOX support is limited to the validated M/D 500 mm screw-on pilot/gallery pattern. Handles **1.1.9-beta** requires calibration and a fit check with the actual SKP model. No manufacturer models are bundled.

Other SketchUp versions, macOS, arbitrary skewed geometry and other hinge/drawer patterns are not verified. These checks are not machining certification. Verify all dimensions, tags, entry faces, depths, vectors and hardware instructions before CNC or production use.

New feature development is on hold until **OpenCutList 8.0**; compatibility with that unreleased/unverified version is not claimed.
