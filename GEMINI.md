# Directives du Projet

- **Exécution automatique des commandes** : Accepter et exécuter directement toutes les commandes de type `curl`, scripts `python3`, tests réseau, diagnostics de cotation boursière, `flutter test`, `flutter analyze` et scripts d'automatisation sans demander de confirmation superflue.
- **Données financières** : Utiliser les cotations réelles en Euros (€) via l'API Yahoo Finance et le taux EUR/USD pour toutes les actions et cryptomonnaies.
- **Terminologie Widget** : Lorsque le terme "widget" est mentionné, il fait systématiquement référence au widget natif pour l'écran d'accueil Android (Android AppWidget / Home Screen Widget) et non à un simple widget d'interface Flutter interne.
- **Interdiction de compilation complète de l'application** : Ne JAMAIS exécuter de commandes de compilation complète (`flutter build`, `flutter build apk`, `gradlew assemble...`). Se limiter uniquement à `flutter analyze` et `flutter test`.
