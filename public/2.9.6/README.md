# ELFIS Door Studio 2.9.6

## 2.9.6 — Finishing orders and dimension labels

- Rename the End Panels order section to Finishing in English/Polish windows, clipboard and complete-order PDF. Include tags anywhere beneath Finishing or Finishing Parts folders, including nested and numbered folders (for example 02 Finishing Parts). Retain support for the standalone endpanels tag.
- Keep finishing products separate from door-profile replacement. The Type column uses the product tag (plinths, pelmets, crowns, end panels, etc.). No profile import is required. Existing manufacturer/source assignment, filtering, consolidation and highlight actions still apply.
- Add Dimensions in model / Wymiary w modelu to the order list. Selected rows show height × width in millimetres on each highlighted occurrence. Preference is remembered. Labels follow nested instance paths, do not change model geometry, skip off-screen/overlapping positions and limit drawing to 200 labels.
- Correct order-list height/width/thickness identification for generated doors with native OpenCutList axes or swapped axes, using physical size and world orientation.
- Keep 2.9.5 native OpenCutList grain compatibility and omit the experimental colour configurator. Native docked custom trays are not part of this update.


In Door Order List, Include Finishing gathers items on tags inside Finishing / Finishing Parts and all their subfolders. Numbered folder names such as 02 Finishing Parts are accepted; the old endpanels tag also works outside that folder. Put end panels, plinths, pelmets, crowns and other finishing products on these tags; they do not need door profiles. Their tag appears as Type. Finishing has its own section in the list, clipboard and PDF. Door-profile replacement remains disabled for these items.

Click a row to highlight every consolidated occurrence. With Dimensions in model enabled, each visible highlighted item displays height × width in mm. Turn the checkbox off to keep only the blue outlines. The setting is remembered; refresh or clear highlight removes the labels. Overlapping labels are suppressed and up to 200 labels are shown at once. These are temporary viewport overlays, not permanent SketchUp dimensions or PDF annotations.

W liście zamówień opcja Uwzględnij Finishing zbiera elementy na tagach wewnątrz folderu Finishing / Finishing Parts i jego podfolderów. Działają też nazwy z numerem, np. 02 Finishing Parts. Stary tag endpanels nadal działa także poza folderem. Umieść na tych tagach panele kończące, cokoły, pelmety, korony i inne elementy wykończenia; nie trzeba dodawać ich profili. Kolumna Typ pokazuje nazwę tagu. Finishing ma własną sekcję listy, schowka i PDF, bez podmiany profilu drzwi.

Kliknięcie wiersza podświetla wszystkie jego kopie. Opcja Wymiary w modelu pokazuje na każdej widocznej podświetlonej sztuce wysokość × szerokość w mm. Wyłącz ją, aby zostawić tylko niebieskie obrysy. Ustawienie jest zapamiętywane. Odświeżenie listy lub wyczyszczenie podświetlenia usuwa napisy. Nakładające się etykiety są pomijane; jednocześnie rysowanych jest najwyżej 200 etykiet. To tymczasowy overlay, a nie trwałe wymiarowanie SketchUpa ani adnotacje PDF.