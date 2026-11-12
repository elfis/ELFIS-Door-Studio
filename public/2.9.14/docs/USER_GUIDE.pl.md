# ELFIS — instrukcja 2.9.14

Interfejs domyślnie jest po angielsku. W nagłówku biblioteki lub zamówienia wybierz **Language / Język → Polski**. Wybór jest zapamiętywany. Nazwy własnych profili, materiałów, tagów, producentów i komponentów nie są tłumaczone. Zmiana języka otwiera ponownie to okno; drugie otwarte okno zachowuje wpisane dane i zmieni język przy kolejnym otwarciu. Niezapisane ustawienia profilu wymagają potwierdzenia odrzucenia.

## Instalacja i trzy ikony

Extensions → Extension Manager → Install Extension → paczka 2.9.0 RBZ, następnie restart SketchUp. Testowanym środowiskiem jest SketchUp Pro 2026 na Windows; inne wersje i macOS nie są potwierdzone. Five-Piece wymaga operacji bryłowych. To aktualizacja biblioteki/podmiany frontów, niezależna od starszej osobnej wtyczki „Drzwi z profilu”.

| Ikona | Działanie |
| --- | --- |
| Drzwi ze strzałką | Podmiana klikniętego frontu aktywnym profilem; można klikać kolejne fronty. |
| Biblioteka / trzy panele | Wybór, dodawanie, ustawienia i usuwanie profili; tworzenie z wymiarów. |
| Lista zamówienia | Zestawienie wymiarów, ilości i kolorów; podświetlanie, przybliżanie, zbiorcza podmiana i schowek. |

Ukryty pasek włączysz przez View → Toolbars. Instrukcja jest też pod Extensions → ELFIS — Documentation / Dokumentacja.

## Biblioteka i przekroje

Wyszukiwarka filtruje nazwy. Gwiazdka dodaje do ulubionych, a przycisk Ulubione filtruje karty. Kliknięta karta staje się aktywnym profilem. Czerwony kosz wymaga potwierdzenia: usuwa własny profil albo ukrywa wbudowany. Istniejące drzwi pozostają. „Przywróć wbudowane” przywraca ukryte wzory. Nie można usunąć ostatniego dostępnego profilu. Przy niezapisanych ustawieniach najpierw zapisz je lub odrzuć.

| Konstrukcja | Jak dodać / co powstaje |
| --- | --- |
| Five-Piece Door | Zaznacz jeden płaski zamknięty przekrój ramiaka: powierzchnię, obrys albo grupę z tym przekrojem. Cztery ramiaki i opcjonalna osobna płycina; szerokie części łączą się na 90°. |
| One-Piece Door | Przekrój od zewnętrznej krawędzi do środka, z płaskim tyłem i pionowym zamknięciem od tyłu do powierzchni środka. Bez rowka na osobną płycinę. Jedna bryła z ciągłym środkiem. |
| Slab | Nazwa i grubość, bez przekroju. Prosta płyta z prostymi krawędziami. |
| J-pull | Parametryczna wnęka: grubość, zasięg, warga, promień i krawędź. Albo własny pełny przekrój boczny z uchwytem na jednym końcu i prostym środkiem. |

Rysuj przekrój w rzeczywistym rozmiarze, nie wyciągnięty ramiak 3D. Five-Piece potrzebuje rozpoznawalnej długiej prostej krawędzi. „Płaska część ramy” to szerokość od zewnętrznej krawędzi do początku ozdobnego frezu; Bastille: 75,5 mm. Płycina potrzebuje prostokątnego rozpoznanego rowka; musi być cieńsza od rowka. Płycina 0 oznacza brak płyciny. Luz nie może wysunąć płyciny z rowka.

One-Piece prowadzi przekrój wokół prostokąta i wypełnia środek; nie oznacza automatycznie litego drewna. Obsługuje poprawne przekroje z wypukłym środkiem i krzywymi podzielonymi na segmenty. Wewnętrzne narożniki są ostre, bez promienia frezu i bez automatycznych ścieżek CNC. Przykład nie jest dokładną kopią Hartford/Parker.

J-pull przebiega przez całą wybraną krawędź. Własny przekrój wczytaj przyciskiem w ustawieniach i sprawdź odwracanie przód/tył oraz końca z uchwytem. Prosty środek jest wydłużany bez skalowania detali. Wymiar prostopadły do uchwytu musi przekraczać dwukrotny zasięg strefy profilowanej. Przykład parametryczny nie jest dokładną kopią Arena. Nie ma uchwytu na części krawędzi ani generatora łączącego ramkę z J-pull.

„Zapisz ustawienia jako profil” zapisuje własny wzór; edycja wbudowanego tworzy własną kopię. „Anuluj dodawanie” odrzuca nowy szkic profilu. W polu producent/źródło wybierz ELFIS, Facade, OS Doors, BA, Tade Moldings lub wpisz nazwę. Sam producent nie dodaje katalogu ani przekrojów.

Przykładowy One-Piece ma przekrój szerokości 70 mm: przy wysokości frontu 140 mm góra i dół nie zostawiają miejsca na środek. Wybierz odpowiedni węższy przekrój, Slab lub skonfigurowany wariant niskiej szuflady. Wymiary graniczne są sprawdzane z tolerancją geometryczną przed tworzeniem i podmianą.

## Niskie szuflady

W rodzinie Five-Piece/One-Piece włącz wariant według wysokości. Wybierz płaski front z grubością albo własny pełny przekrój szuflady. Podaj zakres wysokości, minimalną szerokość i osobne ograniczenia ramy. Własny przekrój ma obejmować dół i górę oraz prosty środek; detale muszą mieścić się w zadanej strefie przy obu krawędziach. Zaimportuj i sprawdź podgląd oraz odwracanie.

Wariant Automatyczny dobiera wykonanie według wysokości. Ramkowy i Niska szuflada wymuszają wariant, ale nadal sprawdzają jego ograniczenia. Zakresy dobierz według dokumentacji danego produktu. Wymiary poza zakresem zatrzymują operację, a błąd w zbiorczej podmianie cofa całość.

## Tworzenie i podmiana

Wpisz wysokość i szerokość w mm, np. 715 × 596, i wybierz „Utwórz z wymiarów”. Komponent powstanie w początku osi bieżącego kontekstu. Five-/One-Piece wymagają obu wymiarów większych niż dwukrotna szerokość przekroju, oprócz ograniczeń rodziny. Slab/J-pull mają grubość powyżej 0,1 do 80 mm i muszą spełniać ograniczenia geometrii.

„Wybierz i klikaj fronty” pozwala podmieniać komponenty bez otwierania szafki. Klikaj szeroką zewnętrzną powierzchnię frontu. Narzędzie celuje w komponent, nie dowolną grupę. Grupowane zwykłe fronty Facade można również podmieniać przez listę, jeżeli rozpoznano płytę. Drzwi można zmieniać wielokrotnie pomiędzy konstrukcjami.

Niebieski obrys wskazuje cel, zielona linia krawędź J-pull. Obsługiwane są obrót, skala i odbicie; deformacja ukośna jest odrzucana. Pozostałe kopie szafki są odseparowywane przy kliknięciu z zewnątrz. W otwartej współdzielonej szafce wyjdź z edycji lub wcześniej użyj Make Unique.

Podmiana zachowuje szerokość, wysokość, tylną płaszczyznę, materiał instancji, tag, widoczność/cienie oraz grupy i komponenty obróbki razem z ich zawartością, atrybutami i położeniem. Nazwy grup obróbki nie są kryterium. Grubość pochodzi z profilu: przy 18 → 22 mm dodatkowe 4 mm wychodzą na zewnątrz. Stara geometria wygenerowana przez plugin jest zastępowana.

Nie są odtwarzane otwory wycięte tylko w starych surowych powierzchniach ani przeliczane głębokości wierceń. Nie powstają nowe ścieżki CNC. Eksport OpenCutList trzeba sprawdzić dla rzeczywistych frontów. Materiały poszczególnych starych powierzchni nie zastępują materiału instancji. W najstarszych drzwiach rozpoznawanie własnych części korzystało z ich standardowych nazw; zmiana nazw tych grup może utrudnić podmianę.

## Nazwy

Extensions → ELFIS — Door Naming / Nazwy drzwi: **Pozostaw nazwy drzwi** (domyślnie) albo **Zmień nazwy drzwi**. Pierwsza opcja zachowuje nazwę instancji; współdzielona definicja może wymagać innej nazwy unikatowej. Druga nadaje nazwę profilu i rozmiar, np. `Bastille 715x596`. Nowe drzwi z wymiarów zawsze otrzymują nazwę profilu i rozmiar.

Numer dopisywany jest tylko przy zajętej nazwie definicji. Od 2.4.1 stosowana jest numeracja SketchUp od `#1`, potem `#2`, z zachowaniem całego wymiaru. Starsza 2.3.1 zaczynała od `#2`. Zmiana opcji nie przemianowuje automatycznie całego projektu.

## Lista zamówienia

Fronty ELFIS są rozpoznawane po atrybutach wtyczki. „Dodaj fronty z tagu Facade ★” włącza zwykłe fronty; gwiazdka oznacza element spoza ELFIS, niezależnie od producenta. Front ELFIS na Facade nie jest liczony dwa razy. Łączone są zgodne profil, konstrukcja, wymiary, materiał, producent i strona J-pull.

„Dodaj Endpanels” pokazuje osobną podlistę. Przypisz tag całej grupie/komponentowi panelu. Działają End Panels / endpanels, różna wielkość liter, spacje, podkreślniki i myślniki. Nie trzeba profilu. Nazwa wskazuje produkt, np. płaski lub T&G. Paneli nie można podmieniać na drzwi; mieszane zaznaczenie również blokuje podmianę. Producenta nadal można przypisywać.

| Przycisk / opcja | Działanie |
| --- | --- |
| Odśwież listę | Odczytuje model, kasuje zaznaczenie i podgląd; użyj po zmianach geometrii. |
| Uwzględnij ukryte fronty | Dodaje także elementy ukryte i z niewidocznych tagów. |
| Filtry profil / kolor / producent | Działają łącznie. Zmiana filtrów kasuje zaznaczenie. |
| Wyczyść filtry | Resetuje trzy filtry. |
| Wyczyść podgląd | Czyści wybór wierszy i obrysy. |
| Nowy profil, Wariant, Zmień profil | Podmienia wszystkie wystąpienia wybranych wierszy; dla J-pull można zachować stronę lub wskazać nową. Jedno Ctrl+Z cofa całość. |
| Przypisz wybranym frontom | Przypisuje producenta/źródło bez przebudowy geometrii. |
| Kopiuj widoczną listę | Kopiuje wszystkie wiersze po filtrach, nie tylko zaznaczone; tabela ze znakami tabulacji do Excela/wiadomości. |
| Kopiuj Endpanels | Kopiuje tylko widoczną podlistę paneli. |

Wymiary uwzględniają zagnieżdżenia i skalę. CNC nie powiększa pomiaru drzwi ELFIS. Facade wymaga bezpośrednich powierzchni płyty; złożone fronty mogą wymagać kontroli. Endpanels może zawierać zagnieżdżoną bryłę; grupy samych wektorów nie rozszerzają pomiaru. Najcieńszy wymiar zwykłej płyty oznacza grubość, pionowa oś powierzchni wysokość. Nietypowe osie, leżące panele i kilka oddzielnych brył trzeba sprawdzić.

Kolor uwzględnia materiał dziedziczony. Próbka przedstawia kolor bazowy, nie teksturę. Pomarańczowy znacznik oznacza dane do kontroli, np. brak profilu, materiału albo kilka materiałów. Obrys jest nakładką widoku, nie geometrią; przy uwzględnianiu ukrytych może wskazywać obiekty przez inne elementy.

## Skróty

| Kontekst | Klawisz / mysz | Wynik |
| --- | --- | --- |
| Narzędzie podmiany | Klik | Podmiana jednego frontu; narzędzie pozostaje aktywne. |
| Narzędzie podmiany | Esc | Zakończenie narzędzia. |
| Podmiana J-pull | Shift + klik | Uchwyt na dole. |
| Podmiana J-pull | Ctrl + klik | Uchwyt po lewej. |
| Podmiana J-pull | Alt + klik | Uchwyt po prawej. |
| Podmiana J-pull | Bez klawisza | Krawędź zapisana w profilu. |
| Lista | Klik | Jeden wiersz, podświetlenie wszystkich jego kopii. |
| Lista | Shift + klik | Zakres widocznych wierszy. |
| Lista | Ctrl + klik | Dodanie/usunięcie pojedynczego wiersza. |
| Lista | Ctrl + Shift + klik | Dodanie zakresu. |
| Lista | Dwuklik | Przybliżenie frontów/paneli. |
| Aktywny wiersz listy | Enter / spacja | Wybranie i podświetlenie. |
| Model SketchUp | Ctrl+Z | Cofnięcie tworzenia, podmiany, całej podmiany zbiorczej lub przypisania producenta. |

Modyfikatory J-pull dotyczą kliknięcia frontu, nie tworzenia z wymiarów. Przy kilku klawiszach priorytet: Shift, Ctrl, Alt. Dla innych konstrukcji nie zmieniają geometrii. W oknie listy te same klawisze zaznaczają wiersze.

## Dane i pomoc

Biblioteka: `%APPDATA%\ELFIS\DoorProfileLibrary\profiles.json`. Zawiera przekroje, ustawienia, aktywny profil, ulubione, ukryte wbudowane oraz opcje nazw i wariantów. Język jest osobną preferencją SketchUp. Zrób kopię biblioteki przy migracji lub cofnięciu wersji; starszy kod może nie obsługiwać nowszych typów. Źródłowy DXF po zapisaniu profilu nie jest potrzebny.

Pusta lista: odśwież, włącz Facade dla zwykłych frontów lub przypisz End Panels całemu panelowi. Za mały front: sprawdź wariant szuflady i ograniczenia rodziny. Zła strona J-pull: sprawdź krawędź, klawisz i odwrócenia przekroju. Nieaktualna lista: odśwież przed działaniem. Nieaktywny kosz: zapisz/odrzuć zmiany i pozostaw przynajmniej jeden profil.

Eksport całego zamówienia do PDF i osobna tabela uchwytów ELFIS są dostępne. Inne akcesoria poza frontami, Endpanels i uchwytami ELFIS pozostają planowane. Historia: CHANGELOG.md. Plany: ROADMAP.md.


## Uchwyty w oknie zamówień

Okno zamówień drzwi zawiera teraz osobną sekcję **Uchwyty** dla modeli wstawionych przez ELFIS Handles. **Odśwież listę** aktualizuje obie sekcje. Wspólne kopiowanie obejmuje widoczne fronty/panele oraz całą włączoną tabelę uchwytów; **Kopiuj uchwyty** kopiuje tylko osprzęt. Filtry profilu/koloru/producenta dotyczą frontów i paneli, a opcja elementów ukrytych również uchwytów. Identyczne produkty i wykończenia są sumowane, także w kopiach zagnieżdżonych szafek. Biblioteka źródłowa uchwytów nie jest wymagana. Uchwyty ręczne bez oznaczenia ELFIS są pomijane.


## Eksport PDF i materiały Slab

**Eksportuj całość do PDF** w nagłówku zamówienia zapisuje jeden plik A4 pionowo, z osobnymi sekcjami: Drzwi/fronty, Panele kończące i Uchwyty. Każda zaczyna się na nowej stronie; długie tabele powtarzają nagłówki. Eksport odświeża dane modelu i obejmuje wszystkie sekcje niezależnie od zaznaczenia, filtrów tabel oraz przełączników sekcji. Nadal obowiązują opcje elementów ukrytych i Facade. Miejsce zapisu wybierasz w oknie Zapisz jako; anulowanie nie zmienia plików. Język okna steruje językiem PDF. Czcionka Arial jest pobierana z Windows i osadzana dla polskich znaków oraz zaznaczania tekstu; nie potrzeba dodatkowego programu PDF.

Przy podmianie na **Slab** materiały dużych powierzchni i każdej krawędzi są przenoszone według położenia powierzchni. Zachowuje to istniejący materiał okleiny używany przez OpenCutList. Wcześniej utraconych przypisań nie można odtworzyć bez oryginalnego frontu lub kopii.


## Faza Slab

W profilu Slab włącz fazę przedniej krawędzi, wpisz wymiar (sugerowane 1,5 mm) i zapisz profil. Istniejące oraz nowe profile mają fazę domyślnie wyłączoną. Faza 45° obejmuje tylko przedni obwód; tył oraz wymiary całkowite pozostają na miejscu. Wąskie prostopadłe boki zachowują osobne materiały ABS, a faza otrzymuje materiał przedniej powierzchni. Opis w zamówieniu i PDF zawiera wymiar fazy.


## OpenCutList grain / 2.9.5

Fronty utworzone przez 2.9.5 można malować narzędziem OpenCutList i zmieniać ich osie narzędziami Zamień długość–szerokość, Zamień przód–tył oraz Dopasuj osie. Stare fronty trzeba raz podmienić, aby dostały nową strukturę. Główny materiał jest na komponencie, a okleina Slab pozostaje na wąskich powierzchniach. Five-Piece także ma kierunek całego frontu: podziały wizualne zostają, ale części ramy są powierzchniami z atrybutami nazw, zamiast osobnych grup do rozkroju. Grupy uchwytów i obróbki pozostają osobno. Konfigurator kolorów nie jest częścią tej wersji.


## Finishing and dimensions / 2.9.6

W liście zamówień opcja Uwzględnij Finishing zbiera elementy na tagach wewnątrz folderu Finishing / Finishing Parts i jego podfolderów. Działają też nazwy z numerem, np. 02 Finishing Parts. Stary tag endpanels nadal działa także poza folderem. Umieść na tych tagach panele kończące, cokoły, pelmety, korony i inne elementy wykończenia; nie trzeba dodawać ich profili. Kolumna Typ pokazuje nazwę tagu. Finishing ma własną sekcję listy, schowka i PDF, bez podmiany profilu drzwi.

Kliknięcie wiersza podświetla wszystkie jego kopie. Opcja Wymiary w modelu pokazuje na każdej widocznej podświetlonej sztuce wysokość × szerokość w mm. Wyłącz ją, aby zostawić tylko niebieskie obrysy. Ustawienie jest zapamiętywane. Odświeżenie listy lub wyczyszczenie podświetlenia usuwa napisy. Nakładające się etykiety są pomijane; jednocześnie rysowanych jest najwyżej 200 etykiet. To tymczasowy overlay, a nie trwałe wymiarowanie SketchUpa ani adnotacje PDF.




### 2.9.8
Dźwięk potwierdzenia i jego przyciski zostały usunięte. PDF całego zamówienia ma białe tło, czarny tekst i cienkie linie. Podglądy SVG pozostają bez zmian.


## Podpórki półek / 2.9.9

Kliknij ikonę podpórek (dwa boki z niebieskimi punktami) i od razu klikaj półki z ustawieniami domyślnymi lub zapisanymi. Ustawienia otworzysz prawym przyciskiem podczas działania narzędzia: średnica, głębokość, odsunięcia od przedniej i tylnej krawędzi półki, położenie środka poniżej spodu oraz rozstaw pionowy. Domyślnie: Ø5, głębokość 12, przód/tył 37, poniżej 2,5 i rozstaw ±32 mm. Następnie klikaj półki regulowane bez wchodzenia do szafki. Prawy przycisk otwiera ustawienia, Esc kończy. Dla kilku półek: wejdź do szafki, zaznacz komponenty półek i kliknij ikonę.

Opcja Zachowaj istniejące pozycje rzędów wykorzystuje dwie zgodne pozycje istniejących rzędów w obu bokach na wysokości podpórki. Wyłącz ją, aby zastosować własne odsunięcia. Przód rozpoznawany jest po komponentach Facade; bez nich przód/tył wynikają z osi geometrycznych półki. Jednakowe odsunięcia nie zależą od tej orientacji. Powstaje 12 grup z okręgami na półkę wewnątrz boków, bez modeli okuć i bez wycinania brył. Grupa: tag Blum Operations; krawędzie okręgu: D5.0_DEPTH12.0, odpowiednio do średnicy i głębokości. Identyczne istniejące wiercenia nie są dublowane. Ponowne użycie aktualizuje własne grupy narzędzia, bez usuwania wierceń importowanych.

Wymagane są oddzielne prostokątne komponenty/grupy półek i boków na Body, pionowe szafki i prostopadłe osie. Elementy zablokowane, zdeformowane lub niejednoznaczne są odrzucane. Kopie szafek są odseparowywane; przy edycji współdzielonego rodzica najpierw użyj Utwórz unikatowy. Półki stałe, wieńce, kołki i śruby pozostają na później. Przesunięcie półki nie uruchamia automatycznej aktualizacji: kliknij ją ponownie dla własnych grup ELFIS. Wiercenia importowane pozostają bez zmian. Ctrl+Z cofa całe kliknięcie lub partię. Sprawdź wektory przed eksportem CNC.


### Ustawienia podpórek / 2.9.10
Okno ustawień otwiera się tylko z menu prawego przycisku aktywnego narzędzia. Podgląd Tag wiercenia / nazwa grupy aktualizuje się na żywo według średnicy i głębokości, również dla wartości dziesiętnych, np. D6.25_DEPTH11.5. Krawędzie okręgu i nazwa grupy używają dokładnie tego tagu; tag grupy pozostaje Blum Operations. Zapisz zapamiętuje ustawienia i aktualizuje aktywne narzędzie; Anuluj pozostawia je bez zmian.

Liczby dodatkowych otworów powyżej i poniżej są niezależne (0–10). Po jednym daje 12 otworów na półkę, po zero daje cztery otwory środkowe. Siatka oznacza rozstaw pionowy. Nowe ustawienia domyślne: przód 57 mm, tył 37 mm; zapisane wartości pozostają. Bez przełącznika rzędu środkowego.


## Usuń podpórki półek / 2.9.11
Kliknij nową ikonę podpórek z czerwonym X, a następnie półkę regulowaną. Jej własne grupy wierceń ELFIS są podświetlane na czerwono i usuwane z boków; półka oraz korpus pozostają. Możesz klikać kolejne półki; Esc kończy. Dla partii zaznacz komponenty półek w bieżącym kontekście i kliknij ikonę usuwania. Ctrl+Z cofa całe kliknięcie/partię. Usuwane są tylko grupy utworzone przez ELFIS, także ze starej pozycji po przesunięciu półki. Wiercenia importowane lub nieoznaczone pozostają, nawet na tym samym tagu. Wynik zero oznacza brak powiązanych grup ELFIS. Dowolna przebudowa hierarchii lub stare kopie odseparowane poza ELFIS mogą utracić powiązanie; narzędzie nie zgaduje własności po samej pozycji.


## Lista zamówienia / 2.9.13

Wybierz sortowanie według wysokości, szerokości/długości lub grubości, rosnąco albo malejąco. Wymiary są sortowane liczbowo wewnątrz grup produktów; ustawienie jest zapamiętywane. Shift zaznacza zakres w widocznej kolejności, Ctrl przełącza pojedyncze wiersze. Escape usuwa zaznaczenie listy i podświetlenie modelu, zarówno w oknie listy, jak i w modelu. Podgląd aktywuje tymczasowe narzędzie; Escape przywraca poprzednie narzędzie, a zmiana narzędzia również usuwa podświetlenie.

Finishing dzieli się według nazw tagów/folderów na Plinths (cokoły), End Panels, Pelmets, Crowns i pozostałe. Tagi powinny znajdować się w Finishing / Finishing Parts. Różne produkty listwowe umieszczaj na osobnych tagach: tag cokołu identyfikuje produkt zakupowy (zaawansowane: atrybut stock_product w słowniku ElfisBastillePodmien). Kolory, dostawcy i przekroje są liczone osobno, niezależnie od nazw poszczególnych elementów.

Dla cokołów ustaw długość listwy (domyślnie 2400 mm) i rzaz piły (domyślnie 3 mm), następnie kliknij Przelicz listwy. Zamawiana ilość dotyczy pełnych listew; + rozwija przypisane odcinki, odpad i stratę na cięciu. Podświetl części wskazuje wszystkie przypisane elementy, a kliknięcie pojedynczego odcinka — tylko jego konkretną kopię. Filtry przeliczają widoczny układ. Odcinki dłuższe od listwy są oznaczane, bez automatycznego dzielenia. Obliczenie nie zawiera zapasu na końcach ani naddatków na skosy. Algorytm ma ograniczony czas pracy; komunikat o układzie przybliżonym oznacza, że minimalna liczba listew nie została potwierdzona.

PDF całego zamówienia używa pionowego A4, pogrubionej ilości przed wymiarami i osobnych sekcji produktów. Zawiera pełne listwy i rozpiski cięcia, niezależnie od filtrów tabeli. Kopiowanie widocznej listy zachowuje filtrowane grupy i rozpiski. Funkcja planuje cięcie długości; nie tworzy ani nie przesuwa geometrii cokołów.

Przekroje zakupowe cokołów są grupowane z dokładnością 0,1 mm, aby zignorować drobne różnice importu (np. 150 i 150,01 mm). Długości cięcia nie są zaokrąglane w ten sposób.


## Wysokości cokołów / 2.9.14

Domyślnie odcinki różnych wysokości (np. 79 i 150 mm) korzystają ze wspólnego rozkładu długości listew. Dla każdego produktu/koloru/dostawcy/grubości płyty szerokość zakupowa jest równa największej wymaganej wysokości. Krótsze, węższe elementy mogą wykorzystać odpady po długości szerszych listew. W drzewie, schowku i PDF każdy odcinek zachowuje rzeczywistą długość i wysokość. To nie jest nesting 2D ani łączenie krótkich resztek w długi element. Zaznacz Rozdziel wysokości listew (79 / 150 mm), aby liczyć je osobno, jak w 2.9.13. Przełącznik przelicza układ i zapamiętuje wybór. Materiały, kolory, produkty i grubości płyty pozostają osobno w obu trybach.
