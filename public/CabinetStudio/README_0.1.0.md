# ELFIS CABINET STUDIO 0.1.0 — wydanie testowe

Osobny projekt i samodzielne rozszerzenie SketchUp Desktop 2022+. Nie wymaga ELFIS Profile Library, synchronizacji zawiasów ani konwersji szafki. Pierwszy moduł: kołki i śruby. Wiercenia podpórek półek nie są częścią tego wydania.

## Obsługa

1. Extensions → ELFIS CABINET STUDIO → Kołki — wskaż panel, albo jedna ikona nowego paska narzędzi.
2. Najedź na panel i sprawdź podgląd. Działa z zewnątrz szafki oraz wewnątrz jej grupy/komponentu. Możesz wcześniej zaznaczyć szafkę, aby ograniczyć przeszukiwanie.
3. Kliknij panel, aby zatrzymać podgląd. Kliknij „Wstaw wiercenia” lub Enter, aby zatwierdzić. Jedno Ctrl+Z cofa całą operację. Esc czyści podgląd.
4. Zwykły tryb używa wzoru 21 wrzecion: D = kołek, S = śruba, - = pomiń. Można też ustawić samą liczbę kołków lub ich rozstaw. Wzór i odsunięcia odnoszą się do osi wskazanego panelu, niezależnie od obrotu całej szafki. Początek to minimum lokalnej osi panelu, nie automatycznie rozpoznany przód szafki.
5. Przytrzymaj Shift: same śruby, z marginesami od rzeczywistych końców materiału i wycięć oraz maksymalnym rozstawem. Zwolnij Shift, aby wrócić do zwykłego trybu. Podgląd zmienia się również po wybraniu panelu. Aby zatwierdzić śruby, trzymaj Shift podczas kliknięcia lub Enter.
6. Overlay pokazuje ustawienia i ma osobne linki „Kołki / wzór D–S…” i „Śruby (Shift)…”. Ustawienia są zapamiętywane w preferencjach SketchUp.

## Geometria i kopie

- Rozpoznaje panel po rzeczywistych płaskich powierzchniach, bez wymogu nazw, tagów ani własnych atrybutów panelu. Obsługuje poziome i pionowe elementy, obroty, odbicia oraz prostopadłe skalowanie.
- Łączy krawędź wskazanego panelu z powierzchnią przylegającego elementu. W trybie Shift obsługuje również powierzchnię wskazanego panelu przylegającą do krawędzi innego, np. plecy przy tylnym wieńcu. Nie traktuje przedniej poprzeczki jako podparcia pleców.
- Kołek: odpowiadające sobie otwory w obu elementach. Śruba: pojedynczy otwór w panelu przyjmującym, jak w poprzednim narzędziu; bez modelu śruby i bez dodatkowego pilota w drugim elemencie. Dla połączenia powierzchnia–krawędź otwór jest od zewnętrznej strony wskazanego panelu.
- Sprawdza pełny obrys otworu i materiał na jego głębokości. Nie wierci w wycięciach zawieszek. W trybie Shift oblicza marginesy osobno dla rzeczywistych ciągłych odcinków materiału. Pozycje wzoru D/S przecinające brak materiału są pomijane.
- Dodaje okręgi wewnątrz istniejących paneli, w grupach nazwanych `D8.0_DEPTH28.0` itd. Grupa ma tag `ELFIS CS Drilling`, okręgi tag średnicy/głębokości. Nie wycina cylindrów w bryle. Okręgi można odczytać z geometrii i nazw, bez własnych atrybutów.
- Ponowne dodanie tego samego otworu pomija duplikaty. Zmiana ustawień nie usuwa wcześniejszych otworów — to narzędzie dodawania, nie automatyczna aktualizacja.
- Wiercenia dotyczą wybranej instancji: w razie potrzeby używa Make Unique dla panelu i jego rodziców. Nie przenosi ani nie przegrupowuje elementów szafki. **Make Unique rozłącza współdzielenie definicji.**
- Jeśli użytkownik edytuje wnętrze współdzielonego komponentu, narzędzie zatrzymuje zapis z konkretnym komunikatem. Należy najpierw zrobić otwartą szafkę jako unikatową albo wykonać wiercenie z zewnątrz. Narzędzie nie zamyka kontekstu edycji samodzielnie.
- Brak obserwatorów modelu i synchronizacji w tle. Wejście do komponentu samo nie dodaje, nie usuwa ani nie przesuwa geometrii.

## Zakres pierwszej wersji

Panele z bezpośrednimi płaskimi powierzchniami, prostokątnymi osiami i grubością 2–60 mm. Obsługiwane są proste wycięcia o krawędziach zgodnych z osiami panelu. Geometria skośna, zaokrąglona, ścinane transformacje, ukryte i zablokowane elementy nie są automatycznie przekształcane. Bardzo krótkie połączenie może nie mieścić ustawionego wzoru/marginesów. W razie niejednoznaczności narzędzie zatrzymuje operację.

## Instalacja i weryfikacja

Instaluj `releases/ELFIS_Cabinet_Studio_0.1.0_TEST.rbz` przez Menedżer rozszerzeń. Paczka zawiera tylko nowe rozszerzenie. Nie instaluje ani nie aktywuje starej synchronizacji zawiasów.

`TEST_RESULTS.json`: testy na tymczasowej geometrii SketchUp, wycofanej po teście. `CONTEXT_TEST_RESULTS.json`: odczytowa kontrola wskazywania i identycznych współrzędnych wierceń z zewnątrz oraz wewnątrz importowanej szafki. Testy nie zapisują pliku SKP. `preview.png` to eksport widoku geometrii testowej; eksport SketchUp nie zawiera nakładki narzędzia.

Skrypty testowe i `mcp_run.py` są lokalnymi narzędziami developerskimi, nie są pakowane do RBZ. `package.py` odmawia nadpisania odmiennej paczki o tym samym numerze. `install.ps1` zachowuje kopie zastępowanych plików i sprawdza SHA256; dotyka tylko plików `elfis_cabinet_studio`.
