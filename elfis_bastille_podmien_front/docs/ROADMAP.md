# Roadmap / Plan rozwoju

Current versions: Doors **2.9.20**, Handles **1.1.9-beta**. The sections below distinguish implemented work from future ideas; no delivery dates are promised.

## Implemented / Gotowe

- Four front styles: Five-Piece, One-Piece, Slab and J-Pull, with supported low-drawer profile families.
- English/Polish interfaces and guides; saved user libraries and preserved installer versions.
- Order tables for Fronts, End Panels and marked ELFIS handles. Consolidated quantities, clipboard copying, front/panel filters and selection tools.
- One complete-order PDF with separate product sections, repeated headings, Unicode fonts and page numbering.
- Standard/knob/edge handle import, fixing-point calibration, live preview/settings, click and batch replacement, and a red X for click removal.
- Slab broad-face and individual edge-band material preservation.

## Order-list selection (2.9.13) / Zaznaczanie z listy zamówienia

- [x] Add ascending/descending sorting by numeric dimensions (height, width/length and thickness), within each product group.
- [x] Dodać sortowanie rosnące/malejące według liczbowych wymiarów (wysokość, szerokość/długość i grubość), osobno wewnątrz każdej grupy produktów.
- [x] Group the order list by product type: Fronts, Plinths, End Panels, Pelmets, Crowns and Handles. Keep Finishing as the parent section for finishing-product subgroups, retain an Other Finishing fallback for unclassified items, and consolidate identical items only within the same product type. Preserve these groups in clipboard and PDF output.
- [x] Grupować listę zamówienia według rodzaju produktu: Fronty, Cokoły (Plinths), Panele kończące (End Panels), Pelmety, Gzymsy (Crowns) i Uchwyty. Finishing pozostaje sekcją nadrzędną dla podgrup elementów wykończeniowych; nierozpoznane elementy trafiają do Pozostałe Finishing. Łączyć identyczne pozycje wyłącznie w obrębie tego samego rodzaju produktu. Zachować podział przy kopiowaniu i eksporcie PDF.

- [x] When doors or panels are selected from the order list and highlighted in the model, Escape clears the highlights and the corresponding selected rows, including multiple selections. Support Escape with focus in either the model or the order-list window. Use Escape instead of a mouse-click clearing action.
- [x] Gdy drzwi lub panele są zaznaczone z listy zamówienia i podświetlone w modelu, Escape usuwa podświetlenie i zaznaczenie odpowiednich wierszy, również przy zaznaczeniu wielu pozycji. Obsługiwać Escape zarówno w modelu, jak i w oknie listy zamówienia. Escape zastępuje kasowanie zaznaczenia kliknięciem myszy.

## Proposed: handle ordering improvements / Rozwój listy uchwytów

- Explicitly mark existing, manually inserted hardware without importing its model.
- Highlight and zoom to handle occurrences from the hardware table; handle-specific filters.
- Review missing manufacturer/code information before ordering.

## Proposed: PDF and accessory ordering / PDF i akcesoria

- [x] Suggest a descriptive filename when saving the order PDF: `<project name>_Doors_<YYYY-MM-DD>.pdf` when the model/project has a meaningful name; otherwise `Doors_<YYYY-MM-DD>.pdf`. Remove characters invalid in filenames and let the user edit the suggested name in the save dialog.
- [x] Przy zapisywaniu PDF zamówienia proponować nazwę `<nazwa projektu>_Doors_<RRRR-MM-DD>.pdf`, jeśli model/projekt ma nadaną nazwę; w przeciwnym razie `Doors_<RRRR-MM-DD>.pdf`. Usuwać znaki niedozwolone w nazwie pliku i umożliwiać zmianę proponowanej nazwy w oknie zapisu.

- [x] Use portrait A4 pages for the order PDF. Place the quantity before the dimensions and render the quantity in bold.
- [x] PDF zamówienia w formacie A4 pionowo. Ilość elementów umieszczać przed wymiarami i wyróżniać pogrubieniem.

- Additional filtered/selected export scopes alongside the current complete-order PDF.
- Colour swatches, company/project branding and configurable order references.
- [x] Finishing product subgroups and whole-length plinth cutting plans with expandable parts (2.9.13).

## Proposed: door and hinge animation / Otwieranie frontów z zawiasami

- [ ] Animate drawer extension and retraction: move the drawer box, front and handle together along the drawer's local slide direction, with configurable travel and an exact return to the closed position. Ordering and machining use the closed position.
- [ ] Animacja wysuwania i wsuwania szuflad: skrzynka, front i uchwyt poruszają się razem zgodnie z lokalnym kierunkiem prowadnic, z ustawianą długością wysuwu i dokładnym powrotem do pozycji zamkniętej. Lista zamówienia i obróbka korzystają z pozycji zamkniętej.

- [ ] Animate opening and closing of doors together with their handles and articulated hinges; support left/right opening and restore the exact closed position. Start with one specific Blum 110° hinge, using separate moving parts and defined pivots. Distinguish approximate presentation motion from a validated hinge mechanism; exact motion requires the selected hinge's linkage and mounting dimensions. Keep ordering and machining based on the closed door geometry.
- [ ] Animacja otwierania i zamykania frontów wraz z uchwytami i ruchomym mechanizmem zawiasów; otwieranie lewe/prawe i powrót do dokładnej pozycji zamkniętej. Początkowo jeden konkretny zawias Blum 110°, z osobnymi częściami ruchomymi i określonymi osiami. Rozróżnić przybliżony ruch prezentacyjny od zweryfikowanej kinematyki: dokładny ruch wymaga wymiarów mechanizmu i montażu wybranego zawiasu. Lista zamówienia i obróbka mają korzystać z geometrii zamkniętego frontu.

## Proposed: placement and profiles / Montaż i profile

- [x] Add click/selection removal of carcass dowel-and-screw drilling, like Shelf Pins removal: click the source rail, fixed shelf or back to remove only the associated ELFIS Carcass Joinery vector groups from the side panels. Preserve imported machining and shelf-pin groups, isolate shared cabinet copies and support one-step Undo.
- [x] Dodać usuwanie wierceń pod kołki i śruby przez kliknięcie/zaznaczenie, tak jak przy podpórkach półek: kliknięcie wieńca, półki stałej lub pleców usuwa z boków tylko powiązane grupy wektorów ELFIS Carcass Joinery. Zachować importowane wiercenia i podpórki, odseparować kopie szafek oraz zapewnić cofanie jednym Ctrl+Z.

- Drilling generation from calibrated handle fixing points.
- Automatic physical-size correction after manual scaling of a front. Currently reapply the handle tool.
- Profile-library import/export, manufacturer packs and more catalogue-specific variants.
- Further CNC/cutter-radius integration, independently tested from visible door geometry.

## Public testing / Testy publiczne

- Clean-install/update/uninstall checks and external testing of standard-handle calibration and placement.
- Additional SketchUp versions/macOS before claiming support.
- Neutral sample models separate from private projects and third-party library assets.
- Signing/store-distribution preparation if distributing through an extension marketplace.

Free under the MIT License; optional Ko-fi donations support AI credits. The full release history is in CHANGELOG.md.

## Central defaults (2.9.18) / Ustawienia domyślne

- [x] Central bilingual panel for default drilling, configurable comma-separated panel tags and visibility-button assignments.
- [x] Review, adopt and resize supported existing drilling groups, preserving centres and cabinet copies.
- [x] Room toggles named groups; existing tag lists remain available per button.
