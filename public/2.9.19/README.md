# ELFIS 2.9.19 — orbit performance fix

Fix repeated model traversal in Room toolbar validation. Matching groups are cached until model transactions or settings changes. Includes ELFIS Tags 1.04.

Native test: 1000 toolbar validations performed no additional hierarchy scans. No model geometry or settings changed. Previous versions preserved.

Install the RBZ through SketchUp Extension Manager and restart SketchUp. The local SketchUp 2026 installation has already been updated.