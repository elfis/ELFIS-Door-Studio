# ELFIS — instrukcja 2.9.0

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

Eksport PDF, osobna lista uchwytów meblowych i inne akcesoria poza Endpanels są planowane, nie są gotowymi funkcjami. Historia: CHANGELOG.md. Plany: ROADMAP.md.
