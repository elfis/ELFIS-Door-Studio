# ELFIS CABINET STUDIO 3.0.3

Studio 3.0 korzysta bezpośrednio z silnika **Kołki i śruby 2.0**, rozdzielonego na dwa przyciski: **Kołki i śruby korpusu 2.0** oraz **Śruby do pleców 2.0**. Pierwszy przycisk przyjmuje tylko wieńce, półki stałe i trawersy; drugi tylko kliknięte panele `Back Wall`.

Rozszerzenie wymaga zainstalowanej głównej wtyczki ELFIS Door Studio. Zachowuje jej ustawienia, podgląd, modyfikatory oraz sposób zapisu wierceń.

## Wybór paneli

1. **Najpierw otwórz grupę lub komponent szafki, tak aby widzieć jej osobne panele. Nie wchodź do wnętrza pojedynczego panelu.** Dopiero wtedy uruchom jedyną ikonę paska **ELFIS CABINET STUDIO** albo Extensions → ELFIS CABINET STUDIO → Kołki — wskaż panel.
2. **Pierwszy klik: panel wiercony.** Obrys turkusowy. Otwory powstaną tylko w tym elemencie.
3. **Drugi klik: panel odniesienia.** Obrys zielony. Jego geometria wyznacza pozycje otworów w pierwszym panelu. Sam panel odniesienia nie otrzymuje wierceń.
4. **Shift+klik** dodaje kolejne odniesienie; ponowne Shift+klik na wybranym odniesieniu usuwa je. Zwykły klik innego odniesienia zastępuje dotychczasowy wybór. Shift nie przełącza trybu wiercenia.
5. W overlayu wybierz **Kołki i śruby — wzór** albo **Same śruby**. Przełączanie zachowuje wybrane panele. Osobne przyciski otwierają ustawienia wzoru i śrub. Tryb oraz ustawienia są zapamiętywane w preferencjach SketchUp.
6. Sprawdź podgląd i kliknij **Wstaw wiercenia** lub Enter. **Od nowa** albo Esc czyści wybór. Jedno Ctrl+Z cofa całą operację.

Przykład: pierwszy klik — lewy bok, drugi — półka dolna, Shift+klik — półka górna. Powstaną dwa rzędy otworów tylko w lewym boku. Prawy bok, plecy i półki nie są automatycznie wiercone. Aby wykonać odpowiadające otwory w półce, uruchom kolejny wybór z półką jako pierwszym panelem.

Najazd pokazuje obrys kandydata, bez automatycznego dobierania innych części szafki. Otwory są planowane dopiero dla zatwierdzonych kliknięciem odniesień. Niewskazane półki i poprzeczki nie są brane pod uwagę.

Wersja 0.2.1 wybiera wyłącznie bezpośrednie panele w aktualnie otwartej szafce. Nie przeszukuje kolejnych poziomów grup i komponentów. Wiercenie spoza szafki, z wnętrza panelu oraz wskazywanie paneli przez dodatkowy kontener jest zablokowane.

Najazd nie analizuje powierzchni paneli: korzysta z zapisanych w pamięci obrysów. Zdarzenia myszy są ograniczone do około 28 na sekundę, bez timerów. Linie okręgów są przygotowywane raz dla podglądu, zamiast przeliczania trygonometrii przy każdym odświeżeniu. Kliknięcie odniesienia wykonuje plan tylko raz. Orbitowanie nie przelicza połączeń.

## Ustawienia i geometria

- Zwykły tryb: wzór 21 wrzecion D = kołek, S = śruba, - = pomiń; alternatywnie sama liczba kołków lub stały rozstaw. Wzór jest mierzony od minimum lokalnej osi elementu wyznaczającego przebieg połączenia, nie od automatycznie rozpoznanego przodu szafki.
- Kołki mają osobne głębokości w krawędzi i w powierzchni. Śruby mają osobną średnicę i głębokość. Wstawiane są tylko otwory należące do pierwszego panelu, także gdy jest nim krawędź półki.
- Tryb samych śrub stosuje margines od rzeczywistych końców ciągłego materiału i maksymalny rozstaw. Wycięcia zawieszek dzielą krawędź na rzeczywiste odcinki. Wzór D/S pomija pozycje przecinające brak materiału.
- Wykrywa rzeczywisty styk krawędź–powierzchnia między wybraną parą paneli. Sprawdza obrys okręgu i materiał na głębokości otworu. Nie wybiera najbliższego nieprzylegającego panelu. Nie wymaga nazw „Shelf”/„Back” ani tagów Bluma.
- Obsługuje poziome i pionowe panele, obroty, odbicia i prostopadłe skalowanie. Pierwsza wersja obsługuje płaskie panele o osiach prostokątnych, grubości 2–60 mm, z bezpośrednimi powierzchniami oraz prostymi wycięciami zgodnymi z osiami. Skośne/zaokrąglone powierzchnie i ścinane transformacje nie są automatycznie przerabiane.
- Dodaje okręgi, nie wycina cylindrów w bryle. Są one w grupach `D8.0_DEPTH14.0` itd., wewnątrz panelu wierconego. Tag grupy: `ELFIS CS Drilling`; tag krawędzi opisuje średnicę/głębokość. Powtórzenie tego samego wiercenia pomija duplikaty. Nowe ustawienia nie usuwają starych otworów.
- Nie przenosi ani nie przegrupowuje części szafki. Dla wybranej instancji wykonuje Make Unique, jeżeli definicja panelu lub rodzica jest współdzielona. To rozłącza współdzielenie definicji; kopie nie otrzymują otworów.
- Działa tylko wewnątrz grupy/komponentu szafki, na jej bezpośrednich panelach. W otwartym współdzielonym komponencie zatrzymuje zapis: najpierw należy zrobić szafkę jako unikatową. Nie zamyka kontekstu edycji za użytkownika.
- Brak obserwatorów i synchronizacji w tle. Samo wejście do komponentu niczego nie dodaje, nie usuwa ani nie przesuwa.

## Instalacja i testy

Paczka: `releases/ELFIS_Cabinet_Studio_0.2.1_TEST.rbz`. Instalacja przez Menedżer rozszerzeń. Poprzednie paczki 0.1.0 i 0.2.0 oraz ich opisy zachowano w `releases`.

`SCOPE_TEST_RESULTS.json`: 44 sprawdzenia wyboru, ograniczeń kontekstu i pamięci podręcznej na tymczasowej geometrii SketchUp, w całości cofniętej po teście. Zachowano kontrolę wielu odniesień, Shift, trybów, kopii, duplikatów oraz wycięć zawieszek. Do testowania geometrii w jednej cofanej operacji adapter udostępnia natywny model i symuluje jedynie otwarty kontekst fixture. `CONTEXT_TEST_RESULTS.json`: 6 odczytowych sprawdzeń z prawdziwym otwarciem importowanej szafki, w tym blokada zewnętrznego wskazywania i pomiar najazdu. W tym modelu średnio 0.0085 ms dla samego wywołania natywnego wskazania i pobrania obrysu; nie jest to pomiar czasu całej klatki ani gwarancja dla innych modeli. Testy nie zapisują SKP.

`TEST_RESULTS.json`, `test_native.rb` i `preview.png` dokumentują poprzedni tryb 0.1.0; `SELECTION_TEST_RESULTS.json` dotyczy 0.2.0. Aktualne testy uruchamia `run_scope.rb`. Narzędzia developerskie nie są częścią RBZ. `package.py` odmawia nadpisania odmiennej paczki o tym samym numerze. `install.ps1` zachowuje kopie zastępowanych plików i sprawdza SHA256.
