# ELFIS Widok Zabudowy 0.1.44 beta

Paczka zawiera aktualny kod podglądu zaznaczonej zabudowy, rzutów, widoku 3D X-ray pojedynczej szafki, eksportu SVG i wydruku/PDF. Zainstaluj RBZ w Menedżerze rozszerzeń SketchUp i uruchom program ponownie. Archiwum zbudowano z lokalnych źródeł i sprawdzono jego zawartość. Testu instalacji w SketchUp nie powtarzano przy publikacji.

# Wersja 0.1.9 beta

- Opcja Prześwity półek — bez frontów, domyślnie włączona; pomiary pojawiają się tylko przy wyłączonych frontach. Oznaczenia mają 6 pkt i są częścią eksportowanego SVG oraz wydruku/PDF.
- Rozpoznawanie poziomych płyt Body nazwanych Shelf… (także Półka…), podział na komory według pokrywających się obrysów; odstępy od powierzchni półek i pasujących poziomych granic komory. Grubości nie mają osobnych oznaczeń.
- Pomijane są szuflady, okucia i grupy obróbki. Bez zapisu atrybutów w komponentach. Opcja zapamiętywana z nazwanym widokiem w SKP.
- Nietypowe komory bez rozpoznanej granicy pokazują tylko odstępy między wykrytymi płytami; podgląd nie zgaduje brakujących wieńców.
- Porównano prześwity z edytorem półek na W1/W2/W3 (216 mm) i L1 (248 mm); zgodne.

# Wersja 0.1.8 beta

- Szerokości szafek: 8 pkt. Wymiary całkowite szerokości i wysokości: 10 pkt. Wysokości poszczególnych szafek: 6 pkt. Rozmiary są przeliczane na rzeczywiste punkty drukarskie dla arkuszy A4 i A3, niezależnie od skali geometrii.

# Wersja 0.1.7 beta

- Jawnie zaznaczone elementy bez frontów pozostają w automatycznych widokach ścian po dodaniu szafki do zaznaczenia. Dotyczy paneli kończących, blend, koron i otwartych półek; przełącznik Finishing Parts nadal kontroluje ich kategorię.
- Elementy bez frontów pozostają we wszystkich kierunkach automatycznych bieżącego zestawu; można je wyłączyć na liście i zapisać osobny zestaw ściany.

# Wersja 0.1.6 beta

- Nowe zaznaczenie wybiera główny kierunek obejmujący najwięcej szafek; kierunek boczny narożnika nie przejmuje domyślnego widoku.
- Ponowne kliknięcie ikony przy otwartym oknie wczytuje aktualne zaznaczenie. Przycisk Wczytaj zaznaczenie działa również po zmianie kontekstu edycji w tym samym modelu.
- Zwykłe odświeżenie zachowuje kierunek ściany według normalnej zamiast niestabilnego numeru ściany. Nowe zaznaczenie zeruje odwrócenie kierunku. Zapisane widoki nie są nadpisywane przez odświeżenie.

# Wersja 0.1.5 beta

- Osobny przełącznik Finishing Parts, domyślnie włączony. Rozpoznaje folder tagów 02 Finishing Parts (również jego podfoldery) i dziedziczy kategorię wewnątrz grup/komponentów. Nie wymaga zmiany istniejących tagów.
- Wyłączenie usuwa te powierzchnie, tylne krawędzie oraz ich wpływ na wymiary. Ustawienie zapisuje się z nazwanym widokiem w SKP.
- Blaty / Worktops pozostają planowaną osobną kategorią.

# ELFIS — Widok zabudowy BETA 0.1.3

Osobny moduł do zwymiarowanych elewacji zaznaczonych szafek. Dotychczasowy podgląd pojedynczej szafki pozostaje bez zmian. Moduł nie zmienia geometrii, materiałów, tagów ani atrybutów modelu. Nie ma obserwatorów ani skanowania podczas obracania modelu.

## Uruchomienie

1. Zaznacz szafki albo grupę zawierającą szafki.
2. Extensions → ELFIS → Cabinet tools → **Widok zabudowy — BETA**, albo osobny pasek **ELFIS — Widok zabudowy BETA**.
3. Wybierz ścianę rozpoznaną po frontach. Dostępne są też cztery kierunki osi modelu, kierunek kamery i odwrócenie widoku.
4. Ustaw Fronty/Wnętrze, opisy, wymiary i kolory. Pozycje można wyłączać osobno na liście.
5. Zapisz SVG albo wybierz Drukuj / PDF. Druk otwiera arkusz w przeglądarce systemowej. Użyj przycisku Drukuj i wybierz Zapisz jako PDF.

Arkusze A4/A3 w poziomie. Skala automatyczna lub 1:10, 1:20, 1:25, 1:50. Do zachowania skali drukuj na wybranym formacie przy 100%, bez dodatkowego dopasowania i nagłówków/stopki przeglądarki. Zbyt duży rysunek przy zadanej skali blokuje eksport, aby uniknąć obcięcia.

## Rozpoznawanie

Fronty: tag Facade/Front/Fronts/Drzwi. Tagi CNC i wektory o nazwach D…DEPTH… są pomijane. Okucia na tagach Hardware/Blum Hardware są pomijane. Sprzęt na tagach Appliances/Dishwasher/Oven/Microwave/Fridge/AGD jest pokazywany jako uproszczona bryła. Rozpoznawanie wykorzystuje też foldery tagów przy pomijaniu operacji i okuć.

Domyślnie uwzględniane są ukryte elementy, ponieważ narzędzia widoczności często ukrywają fronty w modelu. Odznacz tę opcję, aby odzwierciedlić bieżącą widoczność. Widoki ścian są grupowane według kierunku frontów; jedna narożna szafka może należeć do dwóch ścian. Nieobsługiwane/nietypowe grupy można wyłączyć na liście.

## Ograniczenia beta

- Rzut wektorowy rzeczywistych powierzchni, bez perspektywy. Kolory bazowe, bez tekstur i fotorealizmu.
- Wymiary szafki obejmują całą wyeksportowaną geometrię, w tym nóżki i wystające elementy. Nie są wymiarami samych formatek korpusu.
- Wymiary frontu: rzeczywista szerokość × wysokość w płaszczyźnie frontu, niezależnie od skrótu w rzucie. Dla frontów prostopadłych do kierunku patrzenia opisy są pomijane.
- Kolejność zasłaniania bazuje na głębokości powierzchni. Nietypowe przecinające się elementy i skomplikowane narożniki wymagają kontroli. To nie jest pełny algorytm CAD ukrytych krawędzi.
- Oznaczenia i pojedyncze wymiary mogą nakładać się przy szafkach pokrywających się w rzucie; ogranicz zaznaczenie do jednego ciągu lub wyłącz pozycje.
- Brak tabel formatek, wierceń i kart pojedynczych szafek — dotychczasowy moduł preview pozostaje dostępny.
- Skanowanie tylko na żądanie. Limit 30 tys. powierzchni / 10 sekund; przy dużych scenach wybierz mniej szafek.

## Instalacja i powrót

Paczka RBZ: Extension Manager → Install Extension. Moduł jest niezależny. Można go wyłączyć w Extension Manager bez cofania zmian w pozostałych narzędziach ELFIS. Nie zastępuje stabilnego pakietu Door Studio i nie został opublikowany na GitHubie.

## Zmiany w 0.1.1
- Back edges: przerywane krawędzie całej wyeksportowanej geometrii za frontami, bez zmiany ustawień widoku SketchUpa.
- Osobne wysokości każdej szafki, również dolnych i wiszących; przełącznik niezależny od szerokości.
- Całkowity wymiar wysokości z pionowym opisem wewnątrz ramki arkusza.
- Szerokości frontów mierzone w ich własnej płaszczyźnie, zamiast z rzutu.
- 0.1.0 zachowana jako osobna paczka oraz w versions/0.1.0.

## Zmiany w 0.1.2
Uproszczone bryły AGD są zasłaniane przez powierzchnie frontów zwróconych do obserwatora. Usuwa to szary prześwit okapu za frontem W5. Odsłonięty fragment poniżej frontu nadal jest widoczny, a po wyłączeniu frontów bryła okapu pozostaje w podglądzie wnętrza. Model SketchUpa nie jest zmieniany.

## Zmiany w 0.1.3
- Kierunek wąskiego powrotu frontu w szafce narożnej jest ustalany po przylegającym panelu korpusu, a nie wyłącznie po środku obwiedni szafki. Szafka 3 z bieżącego zaznaczenia trafia też do widoku od +X.
- Rysunek techniczny: białe powierzchnie i kontury, bez barw materiałów, cieni i tekstur. Współpracuje z tylnymi krawędziami i widokiem bez frontów.
# Wersja 0.1.4 beta

- Zapisane widoki (np. „Ściana A”) przechowują wskazane instancje szafek, kierunek, ustawienia arkusza i notatkę w atrybutach modelu SKP. Po zapisaniu widoku zapisz również projekt SketchUp.
- „Zapisz jako nowy”: zapisuje tylko szafki uwzględnione w bieżącym widoku. „Zapisz zmiany widoku”: aktualizuje ten widok. „Zastąp bieżącym zaznaczeniem”: zastępuje jego zestaw szafek aktualnym zaznaczeniem SketchUpa, zachowując nazwę.
- „Odśwież zapisane szafki”: ponownie odczytuje geometrię bieżącego zestawu. „Wczytaj zaznaczenie”: otwiera aktualne zaznaczenie bez nadpisywania zapisu. Usunięcie zapisanego widoku nie usuwa szafek.
- Tożsamość szafek jest zapisywana przez pełne ścieżki trwałych identyfikatorów instancji, również w zagnieżdżonych komponentach. Usunięte elementy nie są zastępowane innymi o tej samej nazwie.
- Zewnętrzny łańcuch wysokości pokazuje poziomy szafek oraz prześwity z rzeczywistych współrzędnych modelu.
- Domyślnie włączone: Tylne krawędzie, Rysunek techniczny i Okucia. Interfejs podglądu ma polskie nazwy.
- Okucia z tagów/folderów „Hardware” są przedstawiane uproszczonymi obwiedniami poszczególnych części, bez ciężkich siatek śrub i prowadnic. Nie powiększają wymiarów szafek. Można wyłączyć ich widoczność na arkuszu.
- Notatka (do 300 znaków) jest drukowana na dole arkusza i zapisywana z widokiem. Zachowano poprzednie paczki i źródła.

