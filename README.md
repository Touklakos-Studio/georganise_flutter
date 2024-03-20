# Georganise

Application mobile de gestion de lieux d'intérêts.

## Guide d'installation et d'exécution

### Prérequis

Vous pouvez récupérer le projet en exécutant la commande suivante dans le terminal :
```bash
git clone git@github.com:Touklakos-Studio/georganise_flutter.git
```

### Installation

1. **Installez Android Studio** : 
    - Téléchargez et installez Android Studio depuis [le site officiel](https://developer.android.com/studio).

1. **Installez le Flutter SDK** :
   - Consultez le [guide d'installation officiel de Flutter](https://flutter.dev/docs/get-started/install) pour les instructions détaillées.
   - Assurez-vous d'ajouter le Flutter SDK au PATH.

2. **Vérifier votre installation** :
    - Exécutez la commande suivante dans le terminal :
        ```bash
        flutter doctor
        ```
    - Suivez les recommandations pour résoudre les éventuelles erreurs ou avertissements.

2. **Configurez votre IDE** :
   - *Android Studio* :
     - Installez les plugins Flutter et Dart depuis le marketplace de plugins d'Android Studio.
   - *Visual Studio Code* :
     - Installez l'extension Flutter disponible sur le marketplace de VS Code.

4. **Récupération des Dépendances**:
   - Exécutez la commande suivante dans le terminal pour installer toutes les dépendances nécessaires au projet :
        ```bash
        flutter pub get
        ```

### Exécution 

1. **Configuration d'un Émulateur**:
   - *Android Studio* : Utilisez le Gestionnaire AVD pour créer et démarrer un émulateur Android.
   - *Visual Studio Code* : Assurez-vous qu'un émulateur est en cours d'exécution ou qu'un appareil est connecté.

2. **Lancement du Projet**:
   - Exécutez la commande suivante dans le terminal pour compiler et exécuter l'application sur l'émulateur ou l'appareil connecté :
        ```bash
        flutter run
        ```

### Génération d'un APK 

- Exécutez la commande suivante dans le terminal, à la racine du projet, pour générer un APK :
    ```bash
    flutter build apk
    ```
- L'APK généré se trouve dans `build/app/outputs/flutter-apk/app-release.apk`.
