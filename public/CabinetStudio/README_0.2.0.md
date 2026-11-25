# ELFIS CABINET STUDIO 0.2.0 — wydanie testowe

Samodzielne rozszerzenie SketchUp Desktop 2022+. Służy do dodawania wierceń kołków i śrub do importowanych lub ręcznie zbudowanych paneli. Nie wymaga innych wtyczek ELFIS, konwersji szafki ani własnych atrybutów panelu. Nie obejmuje otworów pod podpórki półek.

## Wybór paneli

1. Uruchom jedyną ikonę paska **ELFIS CABINET STUDIO** albo Extensions → ELFIS CABINET STUDIO → Kołki — wskaż panel.
2. **Pierwszy klik: panel wiercony.** Obrys turkusowy. Otwory powstaną tylko w tym elemencie.
3. **Drugi klik: panel odniesienia.** Obrys zielony. Jego geometria wyznacza pozycje otworów w pierwszym panelu. Sam panel odniesienia nie otrzymuje wierceń.
4. **Shift+klik** dodaje kolejne odniesienie; ponowne Shift+klik na wybranym odniesieniu usuwa je. Zwykły klik innego odniesienia zastępuje dotychczasowy wybór. Shift nie przełącza trybu wiercenia.
5. W overlayu wybierz **Kołki i śruby — wzór** albo **Same śruby**. Przełączanie zachowuje wybrane panele. Osobne przyciski otwierają ustawienia wzoru i śrub. Tryb oraz ustawienia są zapamiętywane w preferencjach SketchUp.
6. Sprawdź podgląd i kliknij **Wstaw wiercenia** lub Enter. **Od nowa** albo Esc czyści wybór. Jedno Ctrl+Z cofa całą operację.

Przykład: pierwszy klik — lewy bok, drugi — półka dolna, Shift+klik — półka górna. Powstaną dwa rzędy otworów tylko w lewym boku. Prawy bok, plecy i półki nie są automatycznie wiercone. Aby wykonać odpowiadające otwory w półce, uruchom kolejny wybór z półką jako pierwszym panelem.

Najazd pokazuje obrys kandydata, bez automatycznego dobierania innych części szafki. Otwory są planowane dopiero dla zatwierdzonych kliknięciem odniesień. Niewskazane półki i poprzeczki nie są brane pod uwagę.

## Ustawienia i geometria

- Zwykły tryb: wzór 21 wrzecion D = kołek, S = śruba, - = pomiń; alternatywnie sama liczba kołków lub stały rozstaw. Wzór jest mierzony od minimum lokalnej osi elementu wyznaczającego przebieg połączenia, nie od automatycznie rozpoznanego przodu szafki.
- Kołki mają osobne głębokości w krawędzi i w powierzchni. Śruby mają osobną średnicę i głębokość. Wstawiane są tylko otwory należące do pierwszego panelu, także gdy jest nim krawędź półki.
- Tryb samych śrub stosuje margines od rzeczywistych końców ciągłego materiału i maksymalny rozstaw. Wycięcia zawieszek dzielą krawędź na rzeczywiste odcinki. Wzór D/S pomija pozycje przecinające brak materiału.
- Wykrywa rzeczywisty styk krawędź–powierzchnia między wybraną parą paneli. Sprawdza obrys okręgu i materiał na głębokości otworu. Nie wybiera najbliższego nieprzylegającego panelu. Nie wymaga nazw „Shelf”/„Back” ani tagów Bluma.
- Obsługuje poziome i pionowe panele, obroty, odbicia i prostopadłe skalowanie. Pierwsza wersja obsługuje płaskie panele o osiach prostokątnych, grubości 2–60 mm, z bezpośrednimi powierzchniami oraz prostymi wycięciami zgodnymi z osiami. Skośne/zaokrąglone powierzchnie i ścinane transformacje nie są automatycznie przerabiane.
- Dodaje okręgi, nie wycina cylindrów w bryle. Są one w grupach `D8.0_DEPTH14.0` itd., wewnątrz panelu wierconego. Tag grupy: `ELFIS CS Drilling`; tag krawędzi opisuje średnicę/głębokość. Powtórzenie tego samego wiercenia pomija duplikaty. Nowe ustawienia nie usuwają starych otworów.
- Nie przenosi ani nie przegrupowuje części szafki. Dla wybranej instancji wykonuje Make Unique, jeżeli definicja panelu lub rodzica jest współdzielona. To rozłącza współdzielenie definicji; kopie nie otrzymują otworów.
- Działa z zewnątrz szafki i wewnątrz jej grupy/komponentu. W otwartym współdzielonym komponencie zatrzymuje zapis: najpierw należy zrobić go jako unikatowy albo wiercić z zewnątrz. Nie zamyka kontekstu edycji za użytkownika.
- Brak obserwatorów i synchronizacji w tle. Samo wejście do komponentu niczego nie dodaje, nie usuwa ani nie przesuwa.

## Instalacja i testy

Paczka: `releases/ELFIS_Cabinet_Studio_0.2.0_TEST.rbz`. Instalacja przez Menedżer rozszerzeń. Wydanie 0.1.0 i jego opis zachowano w `releases`; nie przywracać jego automatycznego doboru połączeń.

`SELECTION_TEST_RESULTS.json`: 35 sprawdzeń nowego wyboru na tymczasowej geometrii SketchUp, w całości cofniętej po teście. Obejmuje ograniczenie wiercenia do pierwszego panelu, wiele odniesień, Shift, przełączanie trybów, kopie, duplikaty oraz wycięcia zawieszek. `CONTEXT_TEST_RESULTS.json`: 5 odczytowych sprawdzeń na importowanej szafce, w tym identyczne pozycje otworów i wskazywanie panelu z zewnątrz i wewnątrz. Testy nie zapisują SKP.

`TEST_RESULTS.json`, `test_native.rb` i `preview.png` dokumentują poprzedni tryb 0.1.0. Aktualne testy uruchamia `run_selection.rb`. Narzędzia developerskie nie są częścią RBZ. `package.py` odmawia nadpisania odmiennej paczki o tym samym numerze. `install.ps1` zachowuje kopie zastępowanych plików i sprawdza SHA256.
