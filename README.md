# AppliGestion Boutique

Bienvenue dans AppliGestion Boutique.

Cette application est faite pour aider une boutique ou un petit commerce à gérer ses ventes, ses produits, ses clients, ses fournisseurs et ses factures depuis un seul outil simple et moderne.

Elle a été pensée pour être facile à utiliser, même pour une personne qui n’est pas très à l’aise avec les outils techniques.

---

## Ce que fait cette application

AppliGestion permet de :

- gérer les produits et le stock,
- enregistrer les ventes rapidement,
- suivre les clients et leurs achats,
- gérer les fournisseurs et les dépenses,
- consulter un tableau de bord avec les chiffres clés,
- générer et imprimer des factures,
- garder toutes les données en sécurité dans le cloud.

En bref, c’est une application de gestion commerciale pour une boutique.

---

## À qui s’adresse ce projet

Cette application est utile pour :

- une boutique de vêtements,
- un magasin de vente de produits divers,
- une petite entreprise avec plusieurs ventes par jour,
- un gestionnaire qui veut suivre le chiffre d’affaires,
- une équipe qui veut un suivi simple et centralisé.

---

## Les fonctionnalités principales

### 1. Gestion des produits

Vous pouvez :

- ajouter des produits,
- rechercher un article,
- filtrer par catégorie,
- voir le stock disponible,
- suivre les prix de vente.

### 2. Gestion des ventes

L’écran de vente permet de :

- choisir les produits à vendre,
- ajouter des quantités,
- calculer le total automatiquement,
- appliquer une réduction pour certains clients,
- valider la vente et générer une facture.

### 3. Gestion des clients

Vous pouvez :

- enregistrer les clients,
- suivre leurs informations,
- voir leurs achats ou soldes,
- mieux gérer les ventes à crédit ou les comptes clients.

### 4. Gestion des fournisseurs et des dépenses

Vous pouvez suivre :

- les fournisseurs,
- les achats effectués,
- les dépenses courantes de la boutique,
- les coûts qui impactent la rentabilité.

### 5. Tableau de bord

L’application affiche des indicateurs comme :

- ventes du jour,
- ventes de la semaine,
- ventes du mois,
- meilleur produit vendu,
- progression par rapport à un objectif.

### 6. Factures

La plateforme permet de :

- générer une facture pour une vente,
- consulter les factures déjà créées,
- imprimer ou exporter le document en PDF,
- partager la facture si nécessaire.

---

## Comment fonctionne l’application

L’application est conçue comme un outil de gestion simple :

- l’utilisateur se connecte,
- il ajoute ou consulte les données de la boutique,
- il enregistre les ventes,
- les informations sont sauvegardées dans une base de données cloud,
- il peut ensuite revenir plus tard pour consulter les données.

Les données sont stockées dans Firebase, une solution cloud de Google qui permet de garder les informations en ligne et accessibles facilement.

---

## Ce que vous devez avoir pour utiliser le projet

Pour lancer l’application, il faut :

- un ordinateur avec Flutter installé,
- un projet Firebase créé,
- un téléphone ou un émulateur pour tester l’application,
- les fichiers de configuration Firebase du projet.

---

## Démarrage rapide

### 1. Installer les dépendances

Depuis le dossier du projet, exécutez :

```bash
flutter pub get
```

### 2. Configurer Firebase

1. Créez un projet Firebase sur la console.
2. Ajoutez votre application Android/iOS/Web selon le cas.
3. Téléchargez le fichier de configuration Firebase.
4. Activez :
   - Authentication
   - Email / Password
   - Cloud Firestore

### 3. Lancer l’application

```bash
flutter run
```

Vous pouvez aussi cibler une plateforme spécifique :

```bash
flutter run -d android
flutter run -d chrome
flutter run -d ios
```

---

## Premier démarrage

Au premier lancement :

- l’application initialise Firebase,
- un écran de connexion s’affiche,
- l’administrateur peut se connecter ou créer un compte.

Ensuite, il est possible de :

- ajouter les produits,
- enregistrer les clients,
- créer les ventes,
- suivre les dépenses et les résultats.

---

## Ce que contient le projet

Le code est organisé de manière simple :

- les écrans pour l’interface utilisateur,
- les modèles de données,
- les services de sauvegarde et Firebase,
- les fichiers de facturation,
- les composants de mise en page.

Cela permet de maintenir le projet plus facilement et d’ajouter de nouvelles fonctions sans casser tout le système.

---

## Technologie utilisée

Le projet est construit avec :

- Flutter pour l’interface,
- Dart comme langage de programmation,
- Firebase pour l’authentification et les données,
- Provider pour la gestion de l’état,
- PDF et impression pour les factures.

---

## Pour un non-développeur

Si vous ne savez pas coder, vous n’avez pas besoin de comprendre tout le code technique pour utiliser l’application.

L’idée principale est simple :

- les produits sont listés,
- les ventes sont enregistrées,
- les clients sont suivis,
- les chiffres sont visibles sur le tableau de bord,
- les factures sont créées automatiquement.

---

## Note importante

Ce projet est conçu pour un usage de gestion commerciale de boutique et peut être adapté selon les besoins de l’entreprise.

Les informations de contact affichées dans l’application peuvent être modifiées selon le contexte réel du magasin.

---

## Licence

Aucune licence n'est actuellement définie pour ce projet

