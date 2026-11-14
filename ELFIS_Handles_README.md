# ELFIS Handles 1.1.9-beta — wersja testowa

> **BETA — Poprawiono import i montaż uchwytów standardowych. Ustaw punkty mocowania i sprawdź rezultat na froncie testowym przed użyciem produkcyjnym.**

Osobny dodatek do ELFIS Door Studio 2.9.1, z własną ikoną i menu **Extensions → ELFIS — Handles**. Nie zmienia plików ani zapisanych profili biblioteki drzwi. W czasie działania rozszerza odczyt wymiarów i przenoszenie elementów, aby obsłużyć uchwyty.

## Nowość w 1.1.4-beta

Czerwony X znajduje się na końcu rzędu. Wszystkie przyciski akcji mają wysokość 36 px; X ma kompaktowy symbol i opis po najechaniu.

## Nowość w 1.1.3-beta

Czerwony przycisk **X** uruchamia usuwanie uchwytów z klikanych frontów. Nie usuwa drzwi. Opis jest dostępny po najechaniu i dla czytników ekranu.

## Nowość w 1.1.2-beta — usuwanie uchwytów

Wybierz **czerwony X** w oknie uchwytów i klikaj komponenty frontów, także wewnątrz szafek. Czerwony obrys wskazuje cel. Usuwane są wyłącznie uchwyty ELFIS; ręczne elementy, front i wiercenia pozostają. Kliknięta kopia szafki jest izolowana. Ctrl+Z cofa jedno usunięcie; Esc kończy narzędzie. Biblioteka modelu uchwytu nie jest wymagana.

## Instalacja

W SketchUp wybierz **Extensions → Extension Manager → Install Extension**, wskaż `ELFIS_Handles_1.1.4-beta.rbz` i uruchom ponownie SketchUp. Pasek włączysz przez **View → Toolbars → ELFIS — Handles**.

## Dodawanie uchwytu

1. Otwórz ikonę **ELFIS — Handles**.
2. Kliknij **Add .skp / Dodaj .skp** i wskaż własny model. Biblioteka początkowo jest pusta.
3. Uzupełnij nazwę, rodzaj (`standard`, `knob`, `edge`), rozstaw śrub w mm, długość, wykończenie, producenta i kod produktu.
4. Ustaw pozycję na schemacie i odstępy, następnie wybierz **Click fronts in model / Klikaj fronty w modelu**.
5. Klikaj komponenty frontów, również wewnątrz szafek. Kliknięcie już wyposażonego frontu podmienia uchwyt.

Model jest kopiowany do `%APPDATA%\ELFIS\HandleLibrary\models`. Baza i ustawienia znajdują się w `handles.json` obok folderu `models`. Kopia całego tego katalogu stanowi kopię biblioteki.

## Zmiany w 1.1.1-beta

Dla standardowych uchwytów **klik Ctrl** przełącza: poziomo na środku u góry / pionowo u góry po prawej. **Klik Shift** przełącza górę/dół na środku w poziomie, albo prawą/lewą stronę u góry w pionie. Zwolnienie klawisza zachowuje pozycję; przytrzymanie nie powtarza zmiany. Odstępy pozostają zachowane. Skrót zastępuje dotychczasową pozycję uchwytu na froncie. Edycja ustawień okna lub ponowne uruchomienie narzędzia zeruje pozycję wybraną klawiaturą. Pochwyty krawędziowe zachowują dotychczasowe skróty przytrzymywane.

## Zmiany w 1.1.0-beta (poprzednie działanie)

- Zmiana pozycji, orientacji lub odstępów odświeża aktywne narzędzie bez ponownego klikania **Click fronts in model**. Sam front zmienia się dopiero po kliknięciu wstawienia lub podmianie zbiorczej.
- **Shift zamienia lewo/prawo dla uchwytów standardowych**, bez zmiany wysokości ani orientacji. Po zwolnieniu wraca pozycja wybrana w oknie. Skróty i zasady montażu pochwytów krawędziowych pozostają bez zmian.
- Osobne odstępy od boku i od góry/dołu. Jawna zmiana pozycji lub orientacji wyłącza zachowywanie starego położenia. Przy samej zmianie modelu nadal można zachować ustawienia poszczególnych frontów.
- Podgląd pokazuje punkty mocowania, w tym pierwszą śrubę. Po najechaniu na front dostaje jego rzeczywiste wymiary i korzysta z tego samego obliczenia co wstawianie.
- Po imporcie zwykłego uchwytu uruchamia się kalibracja. Dla modelu już w bibliotece wybierz **Set fixing points / Ustaw punkty mocowania**. Wskaż środek pierwszej śruby, środek drugiej i płaską powierzchnię styku z drzwiami. Przy gałce drugi punkt wyznacza kierunek czerwonej osi. Rozstaw zostanie zmierzony automatycznie.
- Tymczasowy uchwyt jest pokazywany poza zabudową. Możesz orbitować, aby odsłonić powierzchnię mocowania. W ostatnim kroku niebieska linia ma wskazywać od frontu w stronę uchwytu; **Tab** odwraca kierunek. **Anuluj kalibrację** lub **Esc przy aktywnym widoku modelu** usuwa podgląd i przywraca widok. Podczas kalibracji nie edytuj innych elementów.
- Oryginalny SKP i jego osie pozostają zachowane; zapisujemy osobną transformację mocowania. Starsze modele bez kalibracji nadal korzystają z ich dotychczasowych osi.

## Dotychczasowy sposób ustawiania osi

![Osie montażowe uchwytu standardowego i pochwytu krawędziowego](docs/handles/handle-axes.svg)

Pomarańczowa kropka oznacza początek osi. Lewy rysunek: śruba uchwytu standardowego, na powierzchni styku z drzwiami. Prawy rysunek: przekrój z boku; początek na tylnej górnej krawędzi frontu, w połowie długości pochwytu. Kółko z kropką oznacza oś skierowaną do patrzącego, a kółko z krzyżykiem — w głąb rysunku.

Wczytywany plik SKP musi mieć osie montażowe i rzeczywiste wymiary 1:1. Własny komponent zapisz jako osobny plik przez polecenie komponentu **Save As**, zamiast zapisywać scenę z uchwytem daleko od początku układu.

- **Standard / gałka:** początek przy jednej śrubie, na powierzchni styku z frontem; czerwona X w stronę drugiej śruby, niebieska Z przed front. Zielona oś wynika z prawoskrętnego układu SketchUpa. Dla gałki rozstaw wynosi 0.
- **Edge / pochwyt:** model w pozycji montażu na górze; początek na tylnej górnej krawędzi frontu, w połowie długości pochwytu. Zielona Y ku górze drzwi, niebieska Z ku przodowi. Czerwona X przebiega wzdłuż pochwytu i wynika z prawoskrętnego układu. Pochwyt musi mieć przekrój pasujący do grubości frontu; sam import nie przebudowuje jego kształtu.

## Pozycje i odstępy

**Standard:** osiem pozycji, orientacja pionowa lub pozioma. Przy narożniku wartość odstępu mierzy się od obu sąsiednich krawędzi do osi najbliższej śruby. Przy środku krawędzi wtyczka uwzględnia połowę rozstawu, aby wyśrodkować cały rozstaw mocowań.

**Auto:** połowa szerokości przekroju rozpoznanego frontu Five-Piece / One-Piece. Płaskie fronty, warianty szuflad i nierozpoznane ramki używają wartości z pola odstępu, domyślnie 45 mm. Tryb **Custom / Własny** zawsze używa wpisanej wartości.

**Pochwyt:** góra i dół domyślnie na środku szerokości. Boczne pozycje używają odległości od góry do końca pochwytu. Góra/dół mają osobne przesunięcie w prawo od środka. Mocowanie odnosi się do tylnej powierzchni drzwi.

Podczas klikania pochwytu: **Ctrl — prawa, Alt — lewa, Shift — dół**. Bez klawisza obowiązuje pozycja wybrana w oknie; początkowo góra. Przytrzymany skrót ma pierwszeństwo przed zachowaniem starej pozycji. Nie zmienia to skrótów J-Pull w narzędziu drzwi.

## Podmiana i zestawienie

- **Preserve existing… / Zachowaj…** domyślnie zachowuje pozycję, orientację i odstępy poprzedniego uchwytu. Wyłączenie stosuje bieżące ustawienia.
- **Apply to selected fronts** obsługuje zaznaczone komponenty frontów, a w zaznaczonych szafkach odnajduje fronty już wyposażone w uchwyty.
- **Replace all existing handles** podmienia uchwyty dodane przez ten dodatek w całym modelu, również w ukrytych elementach. Należy wyjść z edycji grupy. Nie podmienia przypadkowych, wcześniej ręcznie wstawionych modeli.
- Zmiana ma pojedynczą operację cofania. Powielone szafki są izolowane podczas edycji konkretnej kopii. Zablokowane obiekty powodują przerwanie operacji.
- Zmiana stylu frontu w ELFIS zachowuje uchwyt i osadza go względem nowej grubości. Niepasujący rozstaw lub pochwyt powoduje wycofanie podmiany z komunikatem.
- **Handle order list / Lista uchwytów** w oknie dodatku grupuje modele i wykończenia, zlicza zagnieżdżone wystąpienia. **Refresh** odświeża, **Copy table** kopiuje tabelę z producentem i kodem. To osobne zestawienie uchwytów; istniejąca tabela zamówień frontów pozostaje bez zmian.

## Ograniczenia tej wersji

Dodatek nie generuje wierceń. Biblioteka nie zawiera modeli producentów. Obsługiwane są prostokątne komponenty frontów; kliknięcie grupy nie zastępuje wskazania komponentu frontu. Nie rozpoznaje dowolnych ramek spoza ELFIS ani kierunku przodu surowych modeli na podstawie ich nazwy. Przy pierwszym montażu na zwykłym froncie najlepiej kliknąć jego przednią powierzchnię. Samodzielne skalowanie frontu po wstawieniu uchwytu skaluje również zagnieżdżony uchwyt — ponowne zastosowanie narzędzia przywraca jego rzeczywisty rozmiar. Nie dodano obserwatora automatycznej korekty po ręcznej edycji geometrii.

Przeszło 46 testów geometrii w SketchUp Pro 2026 na Windows oraz 4 kontrole uruchamiania i anulowania kalibracji na zaimportowanym modelu. Przeszły również testy okna: natychmiastowe aktualizacje, przyciski pozycji, tłumaczenia i wąski układ. Własne modele uchwytów wymagają sprawdzenia osi i dopasowania do frontów.


## Wspólne zamówienie

Drzwi 2.9.3 pokazują uchwyty także we wspólnym oknie zamówienia i eksportują je do jednego PDF razem z frontami i panelami kończącymi. Po aktualizacji całkowicie zamknij i ponownie uruchom SketchUp, aby wczytać nowy kod.


## 1.1.5-beta — Skróty na pasku

Pasek ELFIS — Handles ma trzy przyciski: **Dodaj uchwyt**, **Usuń uchwyt**, **Biblioteka uchwytów**. Dodawanie i usuwanie uruchamiają narzędzia klikania frontów bez otwierania okna. Esc kończy, a Ctrl+Z cofa zmianę modelu. Usuwanie nie wymaga wyboru modelu uchwytu. Biblioteka zachowuje dotychczasowy układ i wszystkie funkcje, zmienia się tylko jej nazwa.

Pierwsze uruchomienie Dodaj ustawia Block Key Bar Handle (jeśli jest zaimportowany), pionowo u góry po prawej. Prywatne modele nie są dołączone do instalatora. Kolejne wybory z biblioteki zostają zapamiętane. Pusta biblioteka otwiera się do importu. Skróty Ctrl/Shift i reguły odstępów działają jak wcześniej.


## 1.1.6-beta

Toolbar: **ELFIS — Handle Tools**. Fix duplicate legacy library icon during a live update; retain the same Handles Library window.


## 1.1.9-beta — Automatyczna długość

Import podpowiada długość z geometrii SKP, a kalibracja przelicza ją wzdłuż osi śrub. Edycja pokazuje wartość Auto i uzupełnia pole długości; zapisz, aby ją przyjąć. Ręczna korekta zostaje zachowana przy kolejnej kalibracji. Wpisz ponownie wartość Auto, aby wrócić do automatyki. Rozstaw śrub pozostaje osobnym wymiarem. Wcześniej wstawione uchwyty zachowują zapisane dane zamówienia do ponownego zastosowania lub podmiany.


## 1.1.8-beta — Unified keyboard controls

Tap Ctrl to toggle vertical/horizontal, Shift to mirror left/right, Alt to mirror top/bottom, and Tab to toggle corner/edge centre. The choice remains after release; holding a key does not repeat the toggle. Standard handles retain the selected mounting position when orientation changes. Edge pulls rotate to match the selected edge; at a corner, orientation chooses the top/bottom edge or side edge. Ctrl moves an edge midpoint to the remembered corresponding midpoint on the other mounting axis. Tab remembers the last corner. Mirrors have no effect on a centre already on the mirror axis.

Edge corners use the configured distance from corner to handle end. Edge midpoints centre the pull (top/bottom retain the configured centre shift). All eight perimeter positions are available in the library. Previously saved side-pull positions keep their old top-offset behaviour until explicitly changed with shortcuts or a position button. Rear fixing, calibration and standard frame/custom offsets are retained. Preview and placement share the same rules.


## 1.1.9-beta — Side pull offset from centre

For a rear-fixing edge pull on a side, set Side: offset from centre in millimetres: zero centres, positive moves up, negative moves down. Editing this field selects the same side in vertical mounting, centred plus the entered distance. The origin remains on the rear fixing plane; the pull never changes sides or flips merely because the offset changes. Bounds checks prevent the pull extending past the door.

For side-mounted edge pulls only, tap Shift to cycle centre → up → down using the chosen absolute distance, or 45 mm if the distance is zero. Alt switches left/right and retains that distance. Ctrl still switches mounting axis and Tab still changes corner/edge-centre anchoring. Standard handles keep all 1.1.8-beta shortcuts. These side-specific Shift/Alt rules supersede the generic table above. After switching back from corner mounting, the side-centre offset remains available.

Pochwyt montowany z tyłu na boku: wpisz odsunięcie od środka, 0 = środek, + = góra, − = dół. Shift przełącza środek/góra/dół o tę odległość (45 mm, jeżeli wpisano zero). Alt przełącza lewy/prawy bok z zachowaniem odsunięcia. Skróty uchwytów standardowych pozostają bez zmian. Mocowanie i obrót pochwytu pozostają zgodne z wybraną krawędzią.
