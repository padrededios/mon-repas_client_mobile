# Mon-Repas Client Mobile

Application mobile **Android / iOS** (Flutter) pour les clients de Mon-Repas.
Reprend l'intégralité des fonctionnalités de la webapp client (`../mon-repas_client`) et consomme la même API (`../mon-repas_api`, port 3502).

📄 **[SPECIFICATIONS.md](./SPECIFICATIONS.md)** — le produit cible : stack, architecture, thème, écrans, contrat API, règles métier.
🗺️ **[ROADMAP.md](./ROADMAP.md)** — le découpage du développement : phases, checklists, jalons, avancement.

## Démarrage rapide

Sur l'iPhone branché en USB (API locale démarrée, iPhone sur le même Wi-Fi que le Mac) :

```bash
./run_device.sh            # détecte l'IP du Mac et lance flutter run
./run_device.sh 192.168.1.42   # ou en forçant l'IP de l'API
```

Compte de test : `client@mon-repas.com` / `password123`.

Tests et analyse statique :

```bash
flutter test
flutter analyze
```
