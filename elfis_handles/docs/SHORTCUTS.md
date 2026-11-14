

## 1.1.8-beta — Unified keyboard controls

Tap Ctrl to toggle vertical/horizontal, Shift to mirror left/right, Alt to mirror top/bottom, and Tab to toggle corner/edge centre. The choice remains after release; holding a key does not repeat the toggle. Standard handles retain the selected mounting position when orientation changes. Edge pulls rotate to match the selected edge; at a corner, orientation chooses the top/bottom edge or side edge. Ctrl moves an edge midpoint to the remembered corresponding midpoint on the other mounting axis. Tab remembers the last corner. Mirrors have no effect on a centre already on the mirror axis.

Edge corners use the configured distance from corner to handle end. Edge midpoints centre the pull (top/bottom retain the configured centre shift). All eight perimeter positions are available in the library. Previously saved side-pull positions keep their old top-offset behaviour until explicitly changed with shortcuts or a position button. Rear fixing, calibration and standard frame/custom offsets are retained. Preview and placement share the same rules.

### Skróty — standardowe i krawędziowe

| Klawisz | Działanie |
|---|---|
| Ctrl | Pionowo / poziomo; pochwyt obraca się do odpowiedniej krawędzi |
| Shift | Odbicie lewo / prawo |
| Alt | Odbicie góra / dół |
| Tab | Narożnik / środek krawędzi; pamięta ostatni narożnik |

Każde naciśnięcie przełącza ustawienie. Po puszczeniu klawisza wybór pozostaje; przytrzymanie nie powoduje kolejnych przełączeń. Odbicie punktu leżącego na osi środka nie zmienia jego pozycji. Przy pochwytach w narożniku odległość jest mierzona do końca uchwytu; model obraca się do wybranej krawędzi, z mocowaniem od tyłu.


## 1.1.9-beta — Side pull offset from centre

For a rear-fixing edge pull on a side, set Side: offset from centre in millimetres: zero centres, positive moves up, negative moves down. Editing this field selects the same side in vertical mounting, centred plus the entered distance. The origin remains on the rear fixing plane; the pull never changes sides or flips merely because the offset changes. Bounds checks prevent the pull extending past the door.

For side-mounted edge pulls only, tap Shift to cycle centre → up → down using the chosen absolute distance, or 45 mm if the distance is zero. Alt switches left/right and retains that distance. Ctrl still switches mounting axis and Tab still changes corner/edge-centre anchoring. Standard handles keep all 1.1.8-beta shortcuts. These side-specific Shift/Alt rules supersede the generic table above. After switching back from corner mounting, the side-centre offset remains available.

Pochwyt montowany z tyłu na boku: wpisz odsunięcie od środka, 0 = środek, + = góra, − = dół. Shift przełącza środek/góra/dół o tę odległość (45 mm, jeżeli wpisano zero). Alt przełącza lewy/prawy bok z zachowaniem odsunięcia. Skróty uchwytów standardowych pozostają bez zmian. Mocowanie i obrót pochwytu pozostają zgodne z wybraną krawędzią.
