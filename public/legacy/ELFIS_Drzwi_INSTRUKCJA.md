# ELFIS — Drzwi z profilu, 1.1.0

SketchUp Pro 2026 na Windows. Tworzy ramę z jednego płaskiego przekroju,
z połączeniem szerokiej części ramy na 90° i profilowaniem wokół płyciny.

## Instalacja

1. Otwórz Extensions → Extension Manager → Install Extension.
2. Wybierz `ELFIS_Drzwi_z_Profilu_1.1.0.rbz`.
3. Pojawi się pasek **ELFIS — Drzwi** z ikoną drzwi oraz polecenie w menu Extensions.
4. Gdy pasek jest ukryty: View → Toolbars → ELFIS — Drzwi.

## Nowy profil

1. Narysuj przekrój w rzeczywistych jednostkach. Ma to być jedna płaska,
   zamknięta pętla, najlepiej z powierzchnią, bez otworów i zbędnych linii.
2. Profil powinien mieć prostą, długą krawędź wyznaczającą szerokość ramy.
   Nie wyciągaj go w gotowy ramiak 3D.
3. Zaznacz samą powierzchnię, wszystkie krawędzie obrysu albo grupę zawierającą ten przekrój.
4. Kliknij ikonę drzwi na pasku **ELFIS — Drzwi**.
5. Wpisz wysokość i szerokość drzwi w milimetrach.
6. Sprawdź szerokość płaskiej części ramy: jest to odległość od zewnętrznej
   krawędzi do początku wewnętrznego ozdobnego profilu. Dla Bastille: 75,5 mm.
7. Podaj grubość płyciny i luz od dna rowka. Dla Bastille: 6 mm i 1 mm.
   Grubość `0` oznacza ramę bez płyciny.
8. Zatwierdź. Nowy komponent powstanie obok źródłowego przekroju.

Jeśli automatyka zamieni wewnętrzną i zewnętrzną stronę nietypowego przekroju,
użyj opcji **Odwróć szerokość profilu** i sprawdź wymiar płaskiej części ramy.

Płycina jest dostępna, gdy skrypt rozpozna prostokątny rowek.
Przy nierozpoznanym rowku wybierz ramę bez płyciny.

## Zapis

Zapisz cały model standardowo albo kliknij komponent prawym przyciskiem
i wybierz **Save As / Zapisz jako**, aby otrzymać osobny plik SKP.

## Jak działa

Skrypt odczytuje przekrój i tworzy zamkniętą, ciągłą ramę. Następnie dzieli
ją na dwa ramiaki i dwie poprzeczki. Szerokie płaskie części łączą się na 90°;
krótkie dopasowanie ozdobnego profilu jest ograniczone do narożników otworu
na płycinę. Rowek nie wychodzi na górne i dolne końce drzwi.

To model geometryczny: nie dodaje czopów, kołków, połączeń klejowych ani okuć.
Testy wykonano na profilu Bastille: dwa rozmiary drzwi, rama bez płyciny,
przekrój obrócony i odbity, wejście jako powierzchnia oraz zamknięty obrys.
Inne kształty przekrojów wymagają sprawdzenia wyniku.
