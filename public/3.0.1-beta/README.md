# ELFIS Door Studio 3.0.1-beta

## 3.0.1-beta — Component finishes and Default faces

- Store the main finish only on the outer front component, matching OpenCutList material assignment. Clear old front/back face materials and generated body-group materials, including when Keep existing is selected.
- Preserve independent Slab narrow-edge materials on faces. Leave handle and machining containers untouched.
- Orient inherited textured grain with body axes, without moving geometry or painting the broad faces. Repeated V/H changes preserve physical dimensions.
- Native SketchUp 2026 tests cover component/face inheritance, ABS retention, shared occurrence isolation, Keep existing, repeated V/H changes and order exports. V/H was also visually checked in SketchUp; V-Ray rendering is not validated.


The main finish is assigned only to the outer front component. Broad front/back and chamfer faces, and generated body groups, use Default so they inherit it. Slab narrow-edge materials stay on their faces for OpenCutList. This also applies to Keep existing; reapply a front to normalize doors created by 3.0.0-beta. V/H uses body axes without moving geometry. Handle and machining groups are excluded.

Główne wykończenie jest przypisane wyłącznie do komponentu frontu. Duże powierzchnie z obu stron, fazy oraz grupy bryły mają Default i dziedziczą ten materiał. Okleina Slab pozostaje na wąskich powierzchniach dla OpenCutList. Dotyczy to także opcji Zachowaj obecne; zastosuj front ponownie, aby poprawić drzwi z wersji 3.0.0-beta. V/H korzysta z osi bryły bez przesuwania geometrii. Grupy uchwytów i obróbki są pomijane.