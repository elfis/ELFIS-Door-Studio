# ELFIS Door Studio 2.9.15

Remove manual Manufacturer / source assignment from the order window. The source column and filter remain. Generated fronts use the library profile's manufacturer before old per-front overrides; metadata remains a fallback if the profile/manufacturer is unavailable. External Facade/Finishing sources are retained. No model geometry, colours or attributes are rewritten.

English/Polish UI checks, standalone Ruby 3.2 profile-source checks, and previous order/plinth UI regressions passed. No live app control or reload was used. Install the RBZ through Extension Manager and restart SketchUp after saving your work, or restart after the installed file update. Previous versions are preserved.

Usunięto ręczne przypisywanie producenta z listy zamówienia. Pozostają kolumna i filtr. Producent frontu pochodzi z profilu; stare metadane służą jako awaryjne źródło. Zmiana nie modyfikuje geometrii ani materiałów.
