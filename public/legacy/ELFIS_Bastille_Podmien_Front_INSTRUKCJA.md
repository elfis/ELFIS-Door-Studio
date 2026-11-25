# ELFIS — Bastille: zamień front, wersja 1.3.0

Osobny plugin dla SketchUp 2026 na Windows. Zawiera własny profil Bastille 84 × 22 mm i własny silnik geometrii. Nie wymaga wcześniejszego pluginu „Drzwi z profilu”.

## Instalacja

W SketchUp otwórz Extensions → Extension Manager → Install Extension i wybierz `ELFIS_Bastille_Podmien_Front_1.3.0.rbz`. Aktualizuje to poprzednią wersję tego narzędzia. Uruchom ponownie SketchUp po aktualizacji. Pasek nazywa się „ELFIS — Bastille zamiana frontu”. Możesz go włączyć przez View → Toolbars.

## Użycie

1. Front powinien być komponentem o prostokątnych wymiarach. Może być wewnątrz grup lub komponentów szafki — nie musisz wchodzić w ich edycję. Narzędzie wybiera najgłębszy komponent pod klikniętą powierzchnią. Same grupy nie są zamieniane.
2. Kliknij ikonę drzwi ze strzałką albo Extensions → Bastille — Zamień kliknięty front.
3. Najedź na szeroką powierzchnię frontu. Pasek stanu pokazuje odczytaną wysokość i szerokość.
4. Kliknij tę powierzchnię. Plugin zastępuje wskazaną instancję drzwiami Bastille w tym samym miejscu, z zachowaniem szerokości i wysokości. Tylna płaszczyzna drzwi pozostaje na miejscu; grubość nowych drzwi wynosi 22 mm i różnica grubości wychodzi na zewnątrz korpusu. Klikaj od strony zewnętrznej frontu.
5. Klikaj kolejne fronty lub naciśnij Esc. Ctrl+Z cofa pojedynczą podmianę.

Rama ma szerokość 84 mm, szerokie części łączą się na 90°, a ozdobny profil biegnie wokół płyciny. Płycina ma 6 mm. Wynik to komponent drzwi zawierający cztery osobne bryły ramy i bryłę płyciny. Pozostaje wewnątrz dotychczasowej grupy lub komponentu szafki.

Zachowywane są tag i materiał przypisane do całej instancji. Od wersji 1.2 przenoszone są również wszystkie grupy i komponenty bezpośrednio wewnątrz starego frontu, razem z ich zagnieżdżoną zawartością. Grupy wierceń i wycięć zachowują typ grupy, nazwy, tagi, materiały, widoczność, atrybuty i położenie w modelu. Nie odtwarza to ubytków wyciętych bezpośrednio w surowej geometrii starej płyty. Od wersji 1.3 przy zmianie grubości na 22 mm zachowywana jest tylna powierzchnia starego frontu. Wektory pozostają na miejscu, podobnie jak zapisane głębokości wiercenia. Przykład: front 18 mm zastąpiony profilem 22 mm wysuwa się o 4 mm na zewnątrz. Fronty utworzone wcześniejszą wersją należy cofnąć i podmienić ponownie.

Pozostałe instancje tego samego frontu nie są zastępowane. Przy kliknięciu z zewnątrz narzędzie automatycznie tworzy unikatowe definicje szafek na ścieżce do frontu, jeżeli mają wiele kopii. Dzięki temu pozostałe kopie szafki nie zmieniają się. Jeżeli już jesteś w edycji współdzielonej szafki, wyjdź z edycji i kliknij front z zewnątrz albo wcześniej użyj Make Unique.

Wersja 1.2 została sprawdzona na czterech rzeczywistych frontach z importu BXF2ABF: 6, 9, 6 i 9 grup wierceń. Po pełnej podmianie nazwy, tagi oraz geometria grup w układzie modelu były identyczne. Sprawdzono również okręgi, atrybuty, skalowanie i odbicie na przykładach testowych. Test nie obejmował eksportu DXF z OpenCutList.

Obsługiwane są obroty, skala i odbicie instancji. Osie definicji powinny odpowiadać krawędziom prostokątnego frontu; wymiary są odczytywane z jego obwiedni. Najmniejszy wymiar jest traktowany jako grubość. Szerokość i wysokość muszą być większe niż 168 mm. Wymagane są narzędzia bryłowe SketchUp Pro.

## Sprawdzenie w otwartym SketchUp 2026

Przeszły testy rzeczywistych wymiarów 715 × 596 × 22 mm, komponentu obróconego i skalowanego, odbicia, innego układu osi oraz klikniętej przeciwnej strony. Sprawdzono pięć brył, cofnięcie i brak zmian pozostałych kopii komponentu. W wersji 1.1 sprawdzono dwa poziomy zagnieżdżenia ze współdzielonymi definicjami szafek, komponent jako wynik oraz cofnięcie. Osobno kliknięto ikonę i front wewnątrz zamkniętej grupy w widoku SketchUp — podmiana zadziałała bez otwierania grupy.
