# ELFIS Door Studio 3.0.0-beta

Experimental saved-finish/configurator update. Install through SketchUp Extension Manager and restart. Tested on SketchUp Pro 2026 Windows.

## Door Configurator and finishes (3.0.0-beta)

Open ELFIS — Door Configurator from the toolbar or Extensions menu. Profile Library continues to manage the door cross-sections and variants. Its Available finishes section assigns a saved palette to each profile. Save a draft profile before assigning its palette.

Use Add finish from model, select a prepared SketchUp material, name the finish and mark whether it has woodgrain. The configurator automatically assigns a newly added finish to its selected profile. No example colours or private materials are bundled. The library creates its own folders under `%APPDATA%/ELFIS/FinishLibrary`.

Choose profile, finish and V/H, then Click fronts or Apply to selected. The latter works on front component instances selected in the current edit context. Click fronts uses the existing nested-front picker. Keep existing preserves each front's own finish and grain. Use the same finish/grain selectors for replacement from selected order rows.

V is vertical, H horizontal, and — is non-directional. Texture grain is assumed to run vertically in the source image. Saved texture scale is retained, not stretched to the door size. Five-Piece rails use H and stiles V; the panel follows the chosen direction. Procedural/triplanar V-Ray shaders may override face UV mapping. This does not change OpenCutList's own grain metadata.

Native SKM snapshots retain material dictionaries including V-Ray data; a separate V-Ray graph backup is saved when present. Existing live model materials are reused. Editing a material manually in SketchUp/V-Ray still affects all geometry sharing it. A V-Ray render round-trip is not yet validated. External V-Ray bitmap paths are retained, not copied/relinked, so keep those source files in place. Raw .vrmat import and a portable texture pack are deferred.

Rollback: reinstall the preserved 2.9.4 RBZ and restart SketchUp. Your pre-update code and profiles.json were backed up under Backups/ELFIS_before_finishes_3.0.0-beta. Back up the new finish/profile databases before restoring an older database; rolling code back alone does not overwrite the libraries.


## Konfigurator i wykończenia (3.0.0-beta)

Otwórz ELFIS — Door Configurator z paska lub menu Rozszerzenia. Biblioteka profili nadal służy do przekrojów i wariantów. Sekcja Dostępne wykończenia przypisuje paletę do profilu; najpierw zapisz nowy profil.

Dodaj wykończenie z modelu: wybierz przygotowany materiał SketchUp, nazwij wykończenie i określ, czy ma usłojenie. Konfigurator przypisuje nowy materiał do aktualnie wybranego profilu. W instalatorze nie ma przykładowych kolorów ani prywatnych materiałów. Foldery w `%APPDATA%/ELFIS/FinishLibrary` tworzą się automatycznie.

Wybierz profil, wykończenie i V/H, potem Klikaj fronty lub Zastosuj do zaznaczonych. Zaznaczenie obejmuje komponenty frontów w bieżącym kontekście edycji. Klikanie korzysta z dotychczasowego wybierania frontu przez grupy. Zachowaj obecne zachowuje osobne wykończenie i kierunek każdego frontu. Te same wybory są przy podmianie pozycji z listy zamówienia.

V = pion, H = poziom, — = bez usłojenia. Przyjmujemy pionowe słoje w źródłowym obrazie tekstury. Skala materiału jest zachowana. Poprzeczki Five-Piece mają słoje wzdłuż długości, ramiaki pionowo, płycina według wyboru. Shadery proceduralne/triplanar V-Ray mogą nadpisywać UV geometrii. Nie zmieniamy oddzielnych ustawień usłojenia OpenCutList.

Zapis SKM zachowuje słowniki materiału, w tym dane V-Ray. Dodatkowo zapisujemy kopię grafu V-Ray. Materiały już obecne w modelu są używane ponownie. Ręczna edycja wspólnego materiału w SketchUp/V-Ray nadal zmienia wszystkie jego wystąpienia. Pełny test renderowania V-Ray pozostaje do wykonania. Ścieżki zewnętrznych tekstur V-Ray są zachowane, bez kopiowania i przepinania plików — pozostaw je na miejscu. Import .vrmat i przenośny pakiet tekstur nie są częścią tej pierwszej wersji.

Powrót: zainstaluj zachowaną paczkę 2.9.4 i zrestartuj SketchUp. Kopia kodu i profiles.json sprzed zmian jest w Backups/ELFIS_before_finishes_3.0.0-beta. Przed przywróceniem starej bazy zrób kopię nowych baz; sama zmiana wersji kodu ich nie nadpisuje.
