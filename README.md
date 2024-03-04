# Georganise : Guide de démarrage du projet Flutter

Guide pour vous aider à configurer et à exécuter le projet sur la machine locale pour le développement et les tests.

## Prérequis

Avant de commencer, assurez-vous que vous avez installé les éléments suivants sur votre machine :

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Un éditeur de code, comme [VS Code](https://code.visualstudio.com/) avec l'extension Flutter, ou [Android Studio](https://developer.android.com/studio)

## Configuration de l'environnement

1. **Clonez le dépôt :** Commencez par cloner le dépôt Git du projet sur votre machine locale en utilisant la commande suivante :

    ```bash
    git clone https://github.com/votre_nom_utilisateur/votre_projet_flutter.git
    ```

2. **Accédez au répertoire du projet :** Changez de répertoire pour accéder à votre projet cloné.

    ```bash
    cd votre_projet_flutter
    ```

3. **Obtenez les dépendances :** Exécutez la commande suivante pour télécharger toutes les dépendances nécessaires spécifiées dans le fichier `pubspec.yaml` :

    ```bash
    flutter pub get
    ```

## Exécution de l'application

Une fois que vous avez configuré votre environnement, vous êtes prêt à exécuter l'application.

1. **Choisissez un émulateur :** Lancez un émulateur Android ou iOS, ou connectez un dispositif physique à votre machine. Vous pouvez vérifier les dispositifs disponibles en exécutant :

    ```bash
    flutter devices
    ```

2. **Exécutez l'application :** Exécutez l'application sur l'émulateur ou le dispositif sélectionné avec la commande :

    ```bash
    flutter run
    ```

## Conseils utiles

- Pour vérifier si votre environnement Flutter est correctement configuré, vous pouvez exécuter `flutter doctor`, qui diagnostiquera les éventuels problèmes avec votre installation de Flutter, Android Studio, ou les dispositifs connectés.
- Si vous rencontrez des problèmes avec les dépendances, essayez de nettoyer le cache des packages avec `flutter pub cache repair` et exécutez à nouveau `flutter pub get`.