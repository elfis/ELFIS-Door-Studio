# ELFIS — instrukcja 2.9.20

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


## Producent / źródło / 2.9.16

Lista zamówienia pokazuje producenta zapisanego w wybranym profilu drzwi. Kolumna i filtr pozostają; usunięto ręczne przypisywanie producenta z listy zamówienia. Metadane frontu są używane awaryjnie, gdy profil lub jego producent są niedostępne. Elementy Facade i Finishing zachowują dotychczasowe źródło. Po zmianie producenta w bibliotece profili odśwież listę.


## Kołki i śruby korpusu (2.9.16)

Uruchom ikonę **Dowels and Screws / Kołki i śruby**. Kliknij poziomy wieniec/półkę stałą na tagu **Body** lub pionowe plecy na **Back Wall**. Potrzebne są dwa przylegające boki na Body. Plecy na Back Wall ustalają przód i tył szafki. Obsługiwane są prostokątne szafki stojące pionowo, również przesunięte, obrócone wokół osi pionowej, odbite i skalowane. Szafki pochylone lub ukośnie zdeformowane nie są obsługiwane.

Możesz wcześniej zaznaczyć kilka paneli. Zaznaczenie całej szafki obejmuje rozpoznane wieńce i półki stałe (nazwy Cabinet base/top, Cross member, Fixed shelf) oraz plecy. Zwykłe półki regulowane są pomijane w takim zbiorczym przetwarzaniu. Kliknięcie lub bezpośrednie zaznaczenie półki nakłada na nią układ połączenia stałego. Wektory powstają wyłącznie w bokach, bez otworów w krawędziach wieńców i półek.

**Prawy przycisk → ustawienia**: kołek Ø8 × 14 mm, śruba Ø3 × 18 mm, pierwsze wrzeciono 30 mm od przodu wieńca / półki stałej, raster 32 mm i 21 pozycji D/S/wyłączone. Domyślny układ z próbki: S D S – D – S D S – D – S D, pozycje 15–21 wyłączone. Krótszy wieniec zachowuje bazę od przodu i pomija niemieszczące się otwory. Korekta osi wynosi 0,2 mm do wnętrza dla dolnego/górnego wieńca; półki stałe korzystają z kierunku dolnego wieńca. Plecy: tylko śruby, równo, skrajne po 55 mm od końców, maksymalny rozstaw 220 mm i oś 12,5 mm od tylnej krawędzi boku.

Zielone okręgi podglądu oznaczają kołki, pomarańczowe śruby. **Esc** kończy narzędzie. **Ctrl+Z** cofa całe zastosowanie. Każdy otwór jest osobną grupą na Blum Operations, wewnątrz komponentu boku. Nazwa grupy i tag okręgu zapisują średnicę i głębokość. Nie powstają powierzchnie ani wycięcia brył. Ponowne użycie odświeża własne grupy i wykorzystuje istniejące pasujące wektory. Wiercenia importowane i podpórki pozostają; zmieniony układ może więc współistnieć ze starymi importowanymi otworami — przed produkcją trzeba je osobno sprawdzić.


## Usuwanie wierceń korpusu i nazwa PDF (2.9.18)

Osobna ikona **Remove Dowels and Screws / Usuń kołki i śruby**, z czerwonym X obok dodawania, usuwa wiercenia powiązane z klikniętym wieńcem, półką stałą lub plecami. Można też zaznaczyć kilka elementów przed uruchomieniem. Czerwony podgląd pokazuje tylko powiązane grupy ELFIS. Wiercenia importowane i podpórki półek pozostają. Powiązanie działa również po przesunięciu elementu. Kopie szafek są odseparowane; zablokowane lub niejednoznaczne powiązania są odrzucane przed usunięciem. Ponowne kliknięcie jest bezpieczne. Esc kończy narzędzie, Ctrl+Z cofa całe usunięcie. Usuwanie nie zależy od aktualnych parametrów wiercenia ani wykrycia styku paneli.

Okno zapisu PDF proponuje **NazwaProjektu_Doors_RRRR-MM-DD.pdf**, z nazwą modelu/projektu i lokalną datą. Model bez nazwy: **Doors_RRRR-MM-DD.pdf**. Znaki niedozwolone w nazwach plików są zastępowane; proponowaną nazwę można zmienić. Zawartość i układ PDF pozostają takie same.

## Centralne ustawienia domyślne (2.9.18)

Otwórz ikoną koła zębatego na pasku **ELFIS — Doors** albo przez **Extensions → ELFIS — Default settings / Ustawienia domyślne**. Panel zawiera domyślne ustawienia narzędzi, bez ustawień drzwi i profili. Pięć zakładek: Podpórki, Kołki i śruby, Istniejące wiercenia, Tagi paneli, Widoczność. **Zapisz ustawienia domyślne** dotyczy następnych operacji. **Przywróć domyślne** wypełnia wartości fabryczne; zatwierdź je przyciskiem zapisu. Dotychczasowe okna pod prawym przyciskiem korzystają z tych samych ustawień wierceń.

**Tagi paneli:** można wpisać kilka nazw po przecinku; wielkość liter nie ma znaczenia. Domyślnie Body dla boków, wieńców/półek stałych i półek regulowanych, Back Wall dla pleców, Facade dla frontów. Tagi pleców muszą być różne od pozostałych paneli. Tag grup operacji jest pojedynczą nazwą (domyślnie Blum Operations); okręgi nadal mają tag średnicy/głębokości. Zapis nie zmienia tagów istniejących paneli.

**Widoczność:** dla każdego dotychczasowego przycisku ELFIS Tags ustaw nazwy tagów albo grup. Room domyślnie przełącza tagi Windows, Walls, Skirting Boards, Room Doors, Floor Plan, Floor i Ceiling. Własne przypisania tagów lub grup można ustawić w tym samym panelu. Pozostałe przyciski zachowują dotychczasowe listy tagów. Kliknięcie przycisku nie tworzy brakujących elementów.

**Istniejące wiercenia:** zaznacz szafkę/grupę w bieżącym kontekście, otwórz zakładkę i rozpoznaj wiercenia. Sprawdź powiązania i liczby, zaznacz wiersze. Przejęcie bez zmiany wymiarów dodaje oznaczenia ELFIS. Przejęcie ze zmianą parametrów dodatkowo zmienia średnicę/głębokość, okręgi i tag obróbki. Podaj osobne wartości dla kołków, śrub (także pleców) oraz podpórek. Środki otworów pozostają na miejscu, inne kopie szafki są odseparowane. Ctrl+Z cofa całość; przejęte wiercenia można usuwać narzędziami ELFIS przez panel źródłowy.

Rozpoznawane są zamknięte okrągłe wektory w grupach/komponentach wewnątrz ustawionych boków, z nazwami/tagami D…_DEPTH… i jednoznacznym powiązaniem geometrycznym. Grupy niejednoznaczne, zablokowane, eliptyczne i nieobsługiwane są pomijane. Po przesunięciu lub zmianie modelu wykonaj ponowne rozpoznanie. Opuść edycję współdzielonej szafki albo wcześniej utwórz ją jako unikatową. Sam zapis ustawień nie zmienia istniejących wierceń.

## Aktualizacja wierceń po przesunięciu panelu (2.9.20)

Użyj **ELFIS — Update drilling / Aktualizuj wiercenia** (ikona zielonych strzałek odświeżania). Kliknij przesuniętą półkę, wieniec lub plecy. Przy zaznaczonych obsługiwanych panelach/szafkach polecenie aktualizuje zaznaczenie. Usuwa stare powiązane grupy ELFIS i tworzy nowy układ według bieżących ustawień domyślnych. Całość cofa jedno Ctrl+Z. Nie działa żaden mechanizm automatycznego odświeżania w tle. Błędna nowa pozycja jest sprawdzana przed usunięciem starych wierceń.

Wiercenia importowane najpierw przejmij w zakładce Istniejące wiercenia, przed przesunięciem panelu. Obsługiwane są również kontenery z wieloma pełnymi okręgami ArcCurve, w tym kołki i śruby dolnego wieńca. Przejęcie rozdziela wybrane okręgi na osobne grupy z zachowaniem położenia i wielkości; pozostałe okręgi i kopie szafki pozostają bez zmian. Pętle z samych odcinków bez ArcCurve nadal wymagają sprawdzenia.

Oś śrub pleców znajduje się teraz automatycznie na środku ich grubości, także przy plecach cofniętych. Dawne stałe odsunięcie od tyłu boku nie jest używane; marginesy od końców i równy rozstaw pozostają regulowane.

## Odczyt ustawień po restarcie (2.9.21)

Przypisania tagów i przycisków widoczności są zapisywane w formacie odpornym na błąd odczytu po restarcie. Wcześniejsze wartości są odzyskiwane z preferencji SketchUpa. Geometria modelu nie jest zmieniana.

## Wycięcia pleców na zawieszki (2.9.21)

Śruby są rozmieszczane na rzeczywistych odcinkach materiału krawędzi pleców, osobno po lewej i prawej stronie. Margines od końca jest mierzony od granicy wycięcia. Zachowany jest równy rozstaw nieprzekraczający ustawionej wartości. Cały przekrój śruby musi mieścić się w materiale; brak miejsca blokuje operację przed zmianą wierceń. Istniejące powiązane otwory popraw poleceniem Aktualizuj wiercenia.

## Śruby pleców od zewnątrz i dalsze klikanie (2.9.23)

Wiercenie pleców dodaje również rzędy śrub od zewnętrznej strony na wysokości rzeczywistych wieńców dolnego i górnego dochodzących do pleców. Przednia listwa górna nie wystarcza. Brak danego wieńca oznacza brak jego rzędu; bez obu wieńców pozostają tylko otwory w bokach. Średnica, głębokość, marginesy i maksymalny rozstaw pochodzą z ustawień śrub pleców. Wysokość osi uwzględnia korektę do wnętrza: 9,2 mm od zewnętrznej powierzchni wieńca 18 mm przy korekcie 0,2 mm. Nowe rzędy obsługuje rozpoznawanie, zmiana parametrów, usuwanie i aktualizacja wierceń. Ponowne zastosowanie usuwa stare rzędy po usunięciu wieńca.

Po wykonaniu dodawania/usuwania na zaznaczonej szafce narzędzie pozostaje w trybie klikania i usuwa zaznaczenie szafki, aby można było od razu podświetlać jej elementy.

## Wycięcia pod zawieszki — Kamar (2.9.24)

Użyj **ELFIS — Hanger Cutouts / Wycięcia pod zawieszki** (ikona panelu z dwoma pomarańczowymi narożnikami L). Kliknij plecy z zewnątrz ich kontekstu edycji albo zaznacz plecy/szafki i uruchom polecenie. Dwa przylegające boki z odpowiednimi tagami służą do ustalenia orientacji i strony zewnętrznej. Esc kończy tryb klikania; prawy przycisk pokazuje parametry Kamar.

Pierwszy wzorzec to Kamar: dwa wycięcia na wylot w górnych narożnikach, każde **55 mm wysokości × 20 mm szerokości**. Osobna zamknięta pętla z sześciu wektorów w kształcie L otacza każde wycięcie od zewnętrznej strony pleców. Jej całkowity wymiar wynosi **63 mm wysokości × 31 mm szerokości**: 8 mm poniżej i 11 mm w stronę środka panelu. Frezowanie L jest reprezentowane przez wektory CNC, bez dodatkowego modelowania zagłębienia w bryle. Nazwa grupy: **Blum Operations**, tag grupy: ustawiony tag operacji (domyślnie Blum Operations). Wszystkie linie mają dokładnie **Kamar D6.0_DEPTH_8.0**. Dawny tag grupy Kamar D6.0_DEPTH_18.5 nie jest nadawany nowym pętlom.

Poprawne istniejące wycięcia pozostają bez zmian. Pasujące stare grupy L są wykorzystywane i otrzymują właściwą nazwę/tag grupy. Ponowne użycie nie dubluje obrysów. Inne lub częściowe wycięcia, blokady i brak materiału zatrzymują operację przed edycją. Pozostałe kopie szafki, materiały i niezwiązane grupy wierceń pozostają zachowane. Całą operację cofa jedno Ctrl+Z. Obsługiwane są pionowe, nieskoszone plecy grubsze niż 8 mm, o wymiarach mieszczących oba narożniki. Moduł ma strukturę wzorców dla kolejnych zawieszek; obecnie dostępny jest Kamar.

## Usuwanie wycięć przez Alt (2.9.25)

Włącz obecną ikonę Wycięcia pod zawieszki. **Przytrzymaj Alt i kliknij plecy**, aby usunąć pasujące obrysy L Kamar i zamknąć oba wycięcia 55 × 20 mm. Podgląd przy trzymanym Alt jest czerwony. Puszczenie Alt natychmiast przywraca dodawanie. Nie ma dodatkowej ikony na pasku.

Wypełnienie przejmuje materiały sąsiednich powierzchni i łączy zbędne współpłaszczyznowe szwy. Pozostałe wiercenia i inne kopie szafki są zachowane. Obsługiwane są też pasujące stare pętle Kamar. Ponowne usuwanie z już naprawionych pleców nie dodaje geometrii. Wspólny tag Kamar pozostaje w modelu, żeby zachować przypisania innych szafek; usuwane są wyłącznie pasujące grupy wektorów wskazanych pleców. Całą operację usuwania i naprawy cofa jedno Ctrl+Z.

## Alt / Ctrl w podpórkach i kołkach (2.9.26)

Obecne narzędzia **Podpórki półek** oraz **Kołki i śruby** mają jednakowe skróty chwilowe:

| Działanie | Wynik | Podgląd |
| --- | --- | --- |
| Klik | Dodaje wiercenia według ustawień | Zwykłe kolory |
| Przytrzymany Alt + klik | Usuwa wiercenia powiązane ze wskazanym panelem | Czerwony |
| Przytrzymany Ctrl + klik | Usuwa stare otwory i odtwarza je w bieżącej pozycji panelu | Zielony |

Puszczenie klawisza przywraca bazowy tryb narzędzia. Gdy oba są trzymane, pierwszeństwo ma Alt. Podgląd przełącza się od razu, bez ruszania myszą. Ctrl poprawia **pozycje otworów, nie przesuwa półki ani wieńca**. Używa istniejącej aktualizacji z jednym Ctrl+Z; nie ma automatycznego odświeżania w tle. Wiercenia importowane bez powiązania trzeba najpierw przejąć w zakładce Istniejące wiercenia. Każde narzędzie aktualizuje tylko swój rodzaj otworów, nawet gdy panel ma oba powiązania. Osobne wcześniejsze ikony usuwania/aktualizacji nadal działają. Po działaniu na zaznaczonych półkach narzędzie podpórek pozostaje aktywne i czyści zaznaczenie, tak jak kołki. Alt w zawieszkach działa jak dotychczas.

## Wiercenia zawiasów (2.9.27)

Uruchom **ELFIS — Hinge Drilling / Wiercenia zawiasów** z menu Extensions lub nowej ikony zawiasu. Kliknij front, również przez zamkniętą grupę szafki. Powstaną wektory CNC we froncie oraz przylegającym boku, bez wstawiania modeli zawiasów i bez animacji.

- Klik: dodaje; pasujących istniejących otworów nie powiela.
- Alt + klik: usuwa wiercenia powiązane przez to narzędzie z frontem, także z boku. Nie usuwa niepowiązanych wierceń importowanych.
- Ctrl + klik: usuwa powiązane wiercenia i odtwarza je według aktualnej pozycji frontu.
- Prawy klik → **Ustawienia wierceń zawiasów**: liczba, odsunięcia od góry/dołu, strona Auto/Left/Right i parametry wierceń. Esc kończy.

Domyślny wzorzec Bluma odczytano z szafki TOP: puszka Ø35, głębokość 13 mm, 5 mm od krawędzi puszki do krawędzi frontu (oś 22,5 mm); otwory Ø8 × 13 mm, rozstaw 45 mm, osie o 9,5 mm dalej w głąb frontu. W boku: dwa Ø5 × 11,5 mm, rozstaw 32 mm, 37 mm od przedniej krawędzi boku. Domyślnie dwie puszki 100 mm od krawędzi frontu, dodatkowe zawiasy równomiernie pomiędzy. Front 715 mm zaczynający się 1 mm powyżej dołu szafki ma osie na 101 i 616 mm od dołu szafki. Parametry można zmienić; narzędzie nie oblicza zgodności z każdym modelem zawiasu.

Auto rozpoznaje stronę po istniejących puszkach Ø35; bez nich wybiera najbliższy bok (przy remisie lewy). Dla pełnego pojedynczego frontu można wskazać Left/Right w ustawieniach. Grupy są wewnątrz komponentu obrabianego panelu i mają ustawiony tag operacji, a krawędzie okręgów tagi D…_DEPTH…. Tagi frontów i boków pochodzą z ustawień domyślnych. Kontrola powierzchni i głębokości chroni przed wierceniami poza panelem lub w wycięciu. Pozostałe kopie szafki, materiały i obce wiercenia pozostają zachowane. Ctrl+Z cofa całą operację; nie dodano obserwatorów w tle.

Obsługiwane są pionowe zamknięte fronty i prostopadłe osie paneli, również obrót szafki w planie, odbicie, skalowanie i edycja unikatowej szafki od środka. Współdzieloną otwartą szafkę trzeba najpierw uczynić unikatową. Importowany otwór w tym samym miejscu, ale o innej głębokości wymaga sprawdzenia; Alt nie przejmuje go automatycznie.

## Uproszczony pasek wierceń (2.9.28)

Z głównego paska usunięto osobne ikony usuwania podpórek oraz kołków i śrub. Przytrzymaj Alt i kliknij odpowiednim głównym narzędziem. Polecenia usuwania są nadal dostępne w menu Extensions. Po aktualizacji uruchom SketchUp ponownie, aby pasek powstał bez starych ikon.

## Adaptacja zawiasów i obrysów Kamar (2.9.29)

W **Ustawieniach domyślnych → Zawiasy** są teraz liczba, strona, odsunięcia względem frontu, odległość puszki od krawędzi, prowadnika od przodu boku i głębokości. Prawy klik narzędzia zawiasów otwiera tę samą zakładkę. Zapis zmienia tylko ustawienia; Ctrl + klik frontu odtwarza powiązane otwory według tych parametrów.

**Istniejące wiercenia → Rozpoznaj w zaznaczonej szafce** rozpoznaje też puszki, mocowania zawiasów we froncie i prowadniki w boku jako osobne rodzaje operacji. Powiązanie importowanych zawiasów korzysta z rzeczywistych wysokości puszek Ø35, również przy innych odsunięciach niż 100 mm, oraz obsługiwanego wzorca Bluma 45/9,5 mm we froncie i 32/37 mm w boku. Do rozpoznania importowanych prowadników w skanowanej szafce musi być zgodny front z co najmniej dwiema puszkami. Nietypowe lub niejednoznaczne wiercenia pozostają niepowiązane. Własne operacje ELFIS zachowują powiązanie po przesunięciu.

Przejęcie bez zmiany wymiarów zachowuje geometrię i łączy otwory w obu panelach z frontem. Przejęcie ze zmianą parametrów zmienia średnicę i głębokość poszczególnych rodzajów, aktualizuje tagi CNC i zachowuje środki otworów. Okręgi złożone w jednej grupie są bezpiecznie rozdzielane. Pozostałe operacje i inne kopie szafki nie zmieniają się. Przejęte wiercenia można usuwać przez Alt i odtwarzać przez Ctrl w narzędziu zawiasów. Ctrl korzysta z aktualnych ustawień, więc przed aktualizacją importu ustaw właściwą liczbę i odsunięcia.

Obrysy Kamar są osobnymi pozycjami **Kamar · L 31 × 63 · D6 / 8 mm**. Przejmowane są tylko obrysy zgodne z wycięciem 55 × 20 mm i obsługiwanym wzorcem frezowania od tyłu. Przejęcie zachowuje kształt; Alt w narzędziu zawieszek usuwa obrys i zamyka wycięcie. Parametry D6 / 8 mm są w tej zakładce zablokowane, a frezowanie nie jest zamieniane na okrąg. Inne zawieszki i dowolne kontury wymagają osobnej obsługi.

## Refresh drilling (2.9.30)

Dotychczasowe polecenie aktualizacji nazywa się teraz **ELFIS — Refresh drilling** i ma ikonę okrężnych strzałek. Zaznacz szafkę albo kilka paneli źródłowych i naciśnij ikonę: odświeży powiązane podpórki, kołki i śruby, wiercenia zawiasów we frontach i bokach oraz obrysy Kamar. Bez zaznaczenia można klikać półkę, wieniec, plecy lub front. Jeśli panel ma kilka rodzajów operacji, zostaną uwzględnione wszystkie. Najpierw sprawdzane są wszystkie nowe pozycje, dopiero później następuje usuwanie. Jedno Ctrl+Z cofa całą operację, a inne kopie szafki zostają zachowane. Wiercenia importowane trzeba najpierw przejąć w Istniejących wierceniach.

Okręgi odtwarzane są według aktualnych ustawień narzędzi. Poprawne wycięcia i obrysy Kamar są zachowywane bez niepotrzebnego zalepiania i ponownego wycinania; brakujący zgodny obrys zostanie odtworzony. Nietypowy kształt wycięcia zostaje odrzucony. Ctrl w poszczególnych narzędziach nadal aktualizuje tylko ich własny rodzaj wierceń. Bez automatycznych obserwatorów w tle.

## Kolejność paska (2.9.31)

Click Front → Profile Library → Order List → separator → Wiercenia zawiasów → Podpórki → Kołki i śruby → Wycięcia w plecach → Refresh drilling → separator → Ustawienia domyślne. Uchwyty mają osobny pasek. Po aktualizacji uruchom SketchUp ponownie, aby zastosować nową kolejność.

## Wiercenia TANDEMBOX M/D (2.9.33)

Dwa działania: **TANDEMBOX Drilling / Wiercenia szuflad** wstawia albo przejmuje zgodne otwory; **Refresh drilling** aktualizuje powiązane wiercenia szuflad, również w zaznaczonej szafce. Nowa ikona znajduje się za zawiasami. Klikaj front z zewnątrz szafki; Alt usuwa jego powiązane otwory z frontu i boków, Ctrl je odtwarza. Prawy klik otwiera **Ustawienia domyślne → Szuflady**.

Pierwszy wzorzec obejmuje pokazane **TANDEMBOX M i D, NL 500 mm**, mocowania frontu przykręcane z otworami pilotującymi Ø2,5 × 3 mm i reling D Ø10 × 12 mm. Nie wstawia modeli okuć, dna ani tyłu, nie zmienia ich geometrii. MERIVOBOX, inne długości i inne mocowania wymagają osobnego wzorca.

Punktem odniesienia jest rzeczywisty front i jego tylna płaszczyzna. Linie mocowań są odsunięte o 15,5 mm do środka od wewnętrznych powierzchni boków. Otwory pilotujące we froncie: 49,5/81,5 mm od bazy; D ma dodatkowo Ø10 na 209,5 mm. Baza to dół frontu plus zakładka dolna. Oś prowadnicy: 35 mm ponad bazą; otwory w boku: 19/37/261 mm od jego przedniej krawędzi. Odpowiada to wszystkim 34 otworom frontów i prowadnic w szafce referencyjnej D, D, M. Krawędzie mają tagi średnica/głębokość, grupy ustawiony tag operacji.

**Zakładka Auto** szuka pełnej szerokości wieńca lub półki przy tylnej płaszczyźnie frontu, do 80 mm ponad jego dołem; pomija części nazwane Drawer/Szuflada. Przyjmuje najbliższą górną powierzchnię. W przykładzie dolny front zaczyna się na 1 mm, a wieniec kończy na 18 mm, więc zakładka wynosi 17 mm; dwa pozostałe fronty mają 0. W nietypowej konstrukcji wybierz zakładkę **Ręczną**. O zakładkę przesuwane są razem wiercenia frontu i boków.

**Wariant Auto** odczytuje zapisane M/D lub obsługiwany układ istniejących mocowań i relingu. Dla nowego nieoznaczonego frontu wybierz M albo D. Narzędzie zapisuje powiązanie i wariant we froncie; zgodne pojedyncze importowane okręgi przejmuje bez powielania. Dla kontenerów z wieloma okręgami najpierw użyj **Istniejące wiercenia → Rozpoznaj → Przejmij**. Zakładka rozdziela mocowania frontu, reling i prowadnice, pozwalając zmieniać ich średnicę/głębokość bez przesuwania środków. Przejmij import przed ręcznym przesuwaniem frontu; niepowiązane stare otwory w bokach nie są zgadywane ani usuwane.

Aktualizacja odtwarza powiązane otwory według aktualnych ustawień. Najpierw sprawdza powierzchnie, głębokości i wolne miejsce w korpusie (minimum 503 mm dla NL 500). Kopie szafek są odseparowywane, a zablokowane i niejednoznaczne pozycje odrzucane. Jedno cofnięcie na klik lub zestaw, bez obserwatorów w tle. Wymagane pionowe fronty i prostopadłe osie paneli.

## Usunięte półki i odświeżanie wierceń (2.9.34)

Po usunięciu półki zaznacz szafkę i użyj **Refresh drilling / Odśwież wiercenia**. Znikną osierocone okręgi podpórek powiązane przez ELFIS z usuniętą półką; pozostałe powiązane operacje zostaną zaktualizowane w jednym kroku cofania. Szafkę bez żadnej półki również można oczyścić: zaznacz ją albo uruchom narzędzie i kliknij jej bok z zewnątrz.

Powiązania są sprawdzane w najbliższym korpusie z dwoma równoległymi bokami. Ukryta lub przemianowana półka pozostaje poprawnym źródłem, kopie szafek są odseparowywane. Zablokowane operacje zatrzymują zestaw przed zmianami. Ręczne, nieoznaczone lub starsze wiercenia bez powiązania źródła pozostają. Zaznaczenie samego boku nie wystarcza do stwierdzenia usunięcia półki. Bez automatycznego odświeżania w tle.

## Baza wierceń wieńca i półki stałej (2.9.35)

Odsunięcie pierwszego wrzeciona dla kołków i śrub jest liczone od **przedniej krawędzi wieńca albo półki stałej**, a nie boku korpusu. Kolejne osie pozostają w rastrze 32 mm od tej samej bazy. Ustawienie 31 mm i cofnięcie wieńca o 0,5 mm dają oś w boku 31,5 mm od jego przodu. Przy cofnięciu o 10 mm będzie to 41 mm. Krótki wieniec pomija osie poza własną głębokością bez przesuwania bazy.

Dotyczy dolnych i górnych wieńców oraz półek stałych, także w korpusach obróconych, odbitych i skalowanych. Śruby pleców i korekta grubości 0,2 mm zachowują osobne dotychczasowe zasady. Aktualizacja nie przesuwa istniejących wierceń przy wczytaniu: zaznacz szafkę i użyj **Refresh drilling** albo Ctrl-klik źródłowego panelu, aby odtworzyć powiązane otwory z aktualnych ustawień. Niepowiązane importowane wiercenia najpierw przejmij.

## Panel zawiasów w widoku modelu (2.9.36)

Uruchom **Wiercenia zawiasów**, aby pokazać panel na ekranie. Najedź na front: podgląd pokazuje numerowane osie puszek w milimetrach od dołu frontu. Przejście kursorem na panel zachowuje podgląd tego frontu. Liczbę zmieniasz przyciskami **− / +**, minimum 2, maksimum 10; układ musi mieścić się we froncie. Odsunięcia od góry i dołu mają krok 1 mm. Kliknięcie wartości pozwala wpisać dokładną liczbę albo odległość. Wybierz Auto / Lewa / Prawa dla strony zawiasów. Zawiasy pośrednie pozostają rozłożone równomiernie.

**Kółko myszy:** nad frontem lub polem liczby zmienia liczbę zawiasów, nad odsunięciem od góry/dołu zmienia tę odległość o 1 mm. Poza frontem i panelem nadal przybliża model. Zmiany dotyczą tylko podglądu do momentu **kliknięcia frontu**. Niepoprawny układ nie zastępuje ostatnich poprawnych ustawień. Alt usuwa powiązane otwory, Ctrl je odtwarza. Prawy klik otwiera pełne ustawienia domyślne, Esc kończy.

Po zastosowaniu szybkich ustawień do powiązanego frontu jego wiercenia we froncie i boku są zastępowane, więc zmniejszenie liczby lub zmiana strony nie pozostawia starych rzędów. Front zapisuje własną liczbę, odsunięcia i stronę; ponowne uruchomienie narzędzia i Refresh drilling zachowują ten układ. Głębokości nadal korzystają z aktualnych ustawień domyślnych. Szybki panel nie zmienia ustawień globalnych. Niepowiązane importowane wiercenia najpierw przejmij. Bez obserwatorów w tle i bez zależności od interfejsu OpenCutList.

## Rozmieszczenie półek (2.9.37)

Uruchom **Rozszerzenia → ELFIS — Arrange Shelves / Rozmieszczenie półek** lub ikonę rozstawu półek. Kliknij szafkę albo zaznacz ją przed włączeniem narzędzia. Panel pokazuje liczbę półek i prześwity numerowane **od dołu do góry**. Wymiary pozostają widoczne w modelu podczas ustawiania podglądu. +/− lub kółko nad liczbą zmienia liczbę półek; kliknięcie wartości pozwala ją wpisać. Zmiana liczby albo przycisk **Rozłóż równo w świetle** ustawia równe prześwity.

**Wpisz prześwity / proporcje**: podaj po jednej wartości na każdą przestrzeń; dla 3 półek są 4 wartości. Separatory: przecinek, średnik lub dwukropek; część dziesiętną zapisuj kropką. Liczby bez jednostki poniżej 10 są proporcjami, od 10 są wymiarami mm. Dopisek mm wymusza wymiar, np. 5mm. **300,200,1,1** daje od dołu 300 i 200 mm, a resztę dzieli na pół. **300,200,3:1** dzieli resztę 75% / 25%. Wartości z % także są proporcjami. Same stałe wymiary muszą wypełniać dostępne światło. Minimalny prześwit: 1 mm.

Wysokość jest mierzona od górnej powierzchni dolnego wieńca do dolnej powierzchni górnego. Następnie odejmowana jest rzeczywista grubość każdej półki. Korpus 720 mm, wieńce 18 mm i 3 półki 18 mm dają 630 mm na cztery prześwity: 300,200,1,1 daje **300 / 200 / 65 / 65 mm**. Bez pełnego górnego wieńca granicą jest góra boków. Istniejące półki zachowują grubość i głębokość; nowe kopiują geometrię, tag i materiał komponentu najniższej półki. Usuwane są najwyższe półki regulowane. Zakres 0–20. Po zejściu do zera zapamiętana definicja wzorca pozwala dodać półki ponownie. Nowy pusty korpus wymaga pierwszej półki wzorcowej; czyszczenie nieużywanych definicji komponentów może usunąć zapamiętany wzorzec.

**Zastosuj + nawierty** przesuwa/dodaje/usuwa półki oraz odtwarza powiązane wektory podpórek na nowych wysokościach z aktualnych ustawień, bez zachowywania starych rzędów. Jedno cofnięcie przywraca cały zestaw. Importowane niepowiązane podpórki najpierw przejmij w **Ustawienia domyślne → Istniejące wiercenia**. Pozostałe operacje zostają. Wieńce i półki stałe są pomijane; przy półce stałej wewnątrz lub pionowych podziałach wybierz oddzielną komorę. Zablokowane panele, nieaktualny podgląd i niemożliwe wymiary są odrzucane. Kopie szafek są odseparowywane. Bez obserwatorów i odświeżania w tle podczas obracania modelu.

## Wycięcia pod zawieszki: niezależne części pleców (2.9.38)

Uruchom **Wycięcia pod zawieszki**, a w panelu ekranowym wybierz **Lewe / Prawe / Oba**. Ctrl przełącza Oba → Lewe → Prawe → Oba. Alt + klik usuwa wybrane wycięcia i zamyka narożniki. Strony liczymy od zewnątrz wskazanych pleców. Podgląd pokazuje wybrane narożniki. Samo włączenie narzędzia nie zmienia zaznaczonej szafki.

Każda część pleców zapamiętuje własny rzeczywisty układ. Refresh zachowuje dwa wycięcia w jednych plecach i jedno w drugich, także przy plecach prostopadłych. Bez zapisanych atrybutów układ jest odczytywany z obsługiwanej geometrii Kamar i pasujących obrysów frezowania; Refresh przejmuje ten układ, bez dodawania brakującego narożnika. Starsze obsługiwane wycięcia nadal można usuwać bez atrybutów. Pozostałe wiercenia i materiały zostają. Kliknięcie można cofnąć jednym Undo, kopie szafek są odseparowywane. Nietypowe i niejednoznaczne wycięcia wymagają sprawdzenia.

Ta wersja rozszerza **wycięcia Kamar oraz ich odświeżanie**. Rozmieszczenie półek narożnych, generowanie podpórek, kołków i śrub oraz narożne układy zawiasów pozostają osobnymi zadaniami. Wymiary wzorca Kamar pozostają bez zmian.

## Szafki narożne L (2.9.39)

Dotychczasowe narzędzia **Rozmieszczenie półek**, **Podpórki**, **Kołki i śruby**, **Zawiasy** i **Refresh drilling** obsługują sprawdzoną szafkę L z prostopadłymi bokami i dwiema częściami pleców. Korzystasz z istniejących ikon.

- **Rozmieszczenie półek:** zaznacz całą narożną. Podgląd zachowuje rzeczywisty obrys L i zaokrąglenie wewnętrzne. Prześwity i proporcje liczone są od dołu, po odjęciu grubości półek i wieńców. Wieńce mogą wystawać bliżej otwarcia niż półki regulowane. Szafka 954 mm, wieńce 18 mm i trzy półki 18 mm: cztery prześwity 216 mm. Zapis 300,200,1,1 daje 300 / 200 / 182 / 182 mm. Zastosuj przesuwa lub kopiuje całe komponenty półek i odtwarza nawierty w jednej operacji. Po zejściu do zera zachowany wzorzec pozwala przywrócić półki wraz z układem podpórek.
- **Podpórki:** wykrywane są rzeczywiste krawędzie styku z płytami. Jednoznacznie przypisane importowane otwory są przejmowane po kliknięciu półki narożnej lub podczas zastosowania rozstawu; stare pozycje są następnie usuwane. Odsunięcia rzędów są zapamiętywane od końców krawędzi i kopiowane na nowe półki. W przykładzie każda półka ma 12 otworów w bokach i 3 w plecach. Otwory w plecach są od zewnątrz, na wylot przez rzeczywistą grubość płyty, także po skalowaniu. Narzędzie zachowuje wskazane importowanym lub zapisanym układem rzędy; nie dodaje ich samowolnie w drugich plecach. Boki zachowują ustawioną głębokość nieprzelotową. Rozstaw pionowy, oś pod półką i liczba otworów dodatkowych pochodzą z bieżących ustawień. Nieprzypisane operacje zostają.
- **Kołki i śruby:** wieńce L i półki stałe otrzymują wiercenia tylko w rzeczywiście przylegających bokach. Wrzeciona liczone są od krawędzi elementu źródłowego, z zachowaniem korekty osi. Każda część pleców jest rozpatrywana osobno, również przy połączeniu pleców ze sobą. Śruby omijają wycięcia. Zewnętrzne rzędy na dole i górze powstają tylko przy rzeczywistym styku z wieńcem.
- **Zawiasy:** oba prostopadłe fronty korzystają z obsługiwanego wzorca puszki i mocowań Blum, każdy ze swoim bokiem. Panel liczby i odsunięć oraz Refresh działają osobno dla frontów. Zapamiętana strona zawiasów podąża za komponentem po odbiciu. To obsługa wierceń, bez wstawiania okuć i animacji; nie dodaje dowolnego wzorca zawiasu ani drzwi łamanych.
- **Refresh:** odświeża powiązane operacje narożnej. Po usunięciu półki usuwa jej osierocone podpórki z boków i pleców. Alt usuwa operacje we właściwym narzędziu. Układy wycięć Kamar lewe/prawe/oba zostają.

Operacje można cofać. Blokady, ukośne deformacje, nieobsługiwane obrysy, niejednoznaczne styki oraz otwory przecinające rzeczywiste krawędzie są odrzucane. Bez obserwatorów i automatycznego odświeżania podczas obracania. Rozstaw wymaga jednej komory, jednakowego obrysu półek regulowanych i półki wzorcowej albo zachowanego szablonu. Wewnętrzna półka stała wymaga osobnej komory. Nierozpoznane wiercenia wymagają sprawdzenia w Istniejących wierceniach.
