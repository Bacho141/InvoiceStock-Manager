# Frontend InvoiceStock Manager

## 🚀 **Application de Gestion InvoiceStock Manager**

Application Flutter moderne pour la gestion des factures et stocks avec authentification JWT, navigation responsive et interface utilisateur intuitive.

## 📦 **Installation**

```bash
cd app/frontend
flutter pub get
```

## 🎯 **Lancement en Développement**

```bash
# Pour Windows
flutter run -d windows

# Pour Android
flutter run -d android

# Pour iOS
flutter run -d ios

# Pour Web
flutter run -d chrome
```

## 🏗️ **Architecture MVC (mise à jour 2025)**

- **Séparation stricte des responsabilités** :
  - **Controllers** : Logique métier, gestion des états, appels aux services.
  - **Services** : Communication avec l’API backend, gestion des requêtes HTTP, gestion des erreurs API.
  - **Screens** : Interface utilisateur uniquement, aucune logique métier.
  - **Widgets** : Composants UI réutilisables, sans logique métier.
  - **Data** : Gestion du cache local (SQLite) et des préférences (SharedPreferences).
  - **Layout** : Composants de mise en page réutilisables (SideBar, AppBar, BottomBar, etc.).
  - **Routes** : Navigation centralisée, mapping des routes vers les écrans, gestion des accès selon le rôle utilisateur.
  - **Utiles** : Fichiers de configuration, constantes, URLs API.
  - **main.dart** : Point d’entrée, initialisation de l’app, restauration du magasin courant.
- **Gestion du magasin courant** :
  - Le magasin sélectionné est stocké dans les SharedPreferences et restauré automatiquement au lancement de l’application.
  - La sélection du magasin est propagée à tous les écrans concernés (stocks, produits, etc.).
- **Navigation centralisée** :
  - Toutes les routes sont définies dans un fichier unique pour garantir la cohérence et la gestion des accès.

---

## ✨ **Fonctionnalités principales (mise à jour 2025)**

- **Gestion multi-magasin** : Sélection, propagation et restauration automatique du magasin courant.
- **Gestion des stocks** : Affichage, ajustement, alertes, gestion des réservations, workflow UX fluide.
- **Gestion des produits** : Ajout, modification, suppression logique (désactivation), filtrage des produits actifs.
- **Ajustement de stock après ajout de produit** : Modal automatique pour initialiser le stock du produit créé.
- **Gestion des utilisateurs** : CRUD, gestion des rôles, activation/désactivation.
- **Navigation intelligente** : Accès aux écrans selon le rôle (caissier, gestionnaire, administrateur).
- **Logs détaillés** : À chaque étape importante (sélection magasin, ajustement, création, erreurs, navigation, etc.), respect du format `[NIVEAU][Classe] Message`.
- **Gestion des erreurs** : Affichage de messages clairs à l’utilisateur pour toute erreur API ou logique, fallback UX en cas d’échec.
- **Synchronisation locale** : Utilisation de SQLite pour le cache et SharedPreferences pour les préférences et la session.
- **Design responsive et moderne** : Palette violette, gradients, animations Lottie, layouts adaptés desktop/mobile/tablette.

---

## 🛣️ **Routes principales et navigation (mise à jour 2025)**

| Route                | Écran associé              | Accès par rôle                | Description                                      |
|----------------------|---------------------------|-------------------------------|--------------------------------------------------|
| `/`                  | WelcomeScreen             | Tous                          | Écran d’accueil, animations, accès connexion     |
| `/login`             | LoginScreen               | Tous                          | Connexion utilisateur                            |
| `/dashboard`         | DashboardScreen           | Tous                          | Tableau de bord personnalisé                     |
| `/new-sale`          | NewSaleScreen             | Caissier, Gestionnaire, Admin | Création d’une nouvelle vente                    |
| `/invoices`          | InvoicesScreen            | Caissier, Gestionnaire, Admin | Gestion des factures                             |
| `/products`          | ProductsScreen            | Gestionnaire, Admin           | Catalogue des produits                           |
| `/stocks`            | StocksScreen              | Gestionnaire, Admin           | Gestion des stocks multi-magasin                 |
| `/reports`           | ReportsScreen             | Admin                         | Tableaux de bord, analyses, rapports             |
| `/user-management`   | UserManagementScreen      | Admin                         | Gestion des utilisateurs                         |
| `/settings`          | SettingsScreen            | Admin                         | Paramètres de l’application                      |

- **Navigation centralisée** :
  - Toutes les routes sont gérées dans un fichier unique pour garantir la cohérence.
  - La navigation est contrôlée selon le rôle utilisateur (redirection automatique si accès refusé).
  - La session et le magasin courant sont vérifiés avant chaque navigation sensible.
- **Gestion des accès** :
  - Les écrans sont accessibles selon le rôle (caissier, gestionnaire, administrateur).
  - Les tentatives d’accès non autorisées redirigent vers l’écran approprié.

---

## 🔧 **Configuration Technique**

### **Routes** (`routes/routes.dart`)
```dart
class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const WelcomeScreen(),
    '/login': (context) => const LoginScreen(),
    '/dashboard': (context) => const DashboardScreen(),
    '/new-sale': (context) => const NewSaleScreen(),
    '/invoices': (context) => const InvoicesScreen(),
    '/products': (context) => const ProductsScreen(),
    '/stocks': (context) => const StocksScreen(),
    '/reports': (context) => const ReportsScreen(),
    '/user-management': (context) => const UserManagementScreen(),
    '/settings': (context) => const SettingsScreen(),
  };
}
```

### **URLs API** (`utiles/api_urls.dart`)
```dart
class ApiUrls {
  static const String baseUrl = 'http://192.168.0.114:5000/api';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String verifySession = '$baseUrl/auth/verify';
  static const String sessionInfo = '$baseUrl/auth/session-info';
  static const String users = '$baseUrl/users';
}
```

## 📦 **Dépendances**

### **Packages Principaux**
```yaml
dependencies:
  flutter:
    sdk: flutter
  lottie: ^2.7.0                    # Animations
  animated_background: ^2.0.0        # Fonds animés
  http: ^1.1.0                      # Communication API
  shared_preferences: ^2.2.2         # Stockage local
  sqflite: ^2.3.0                   # Base de données SQLite
  path: ^1.8.3                      # Gestion des chemins
  cupertino_icons: ^1.0.8           # Icônes iOS
```

### **Migration de Packages**
- **Remplacement** : `flutter_secure_storage` → `shared_preferences`
- **Raison** : Compatibilité Windows améliorée
- **Impact** : Stockage local sécurisé maintenu

## 🛡️ **Sécurité et Gestion d'Erreurs**

### **Gestion des Sessions**
1. **Stockage local sécurisé**
   - Token JWT stocké localement
   - Informations utilisateur persistantes
   - Nettoyage automatique lors de la déconnexion

2. **Validation côté client**
   - Vérification de session avant navigation
   - Redirection automatique si session invalide
   - Gestion des erreurs de connexion

3. **Déconnexion sécurisée**
   - Invalidation côté serveur
   - Nettoyage local garanti
   - Confirmation utilisateur

### **Logs et Debug**
```
[SCREEN][LoginScreen] Bouton SE CONNECTER cliqué
[CONTROLLER][AuthController] Appel login pour admin
[SERVICE][AuthService] Tentative de login pour admin
[CONTROLLER][AuthController] Token et rôle stockés
[LAYOUT][MainLayout] Navigation vers: /dashboard
```

## 🎨 **Design et UX**

### **Palette de Couleurs**
- **Primaire** : Violet (#7717E8)
- **Secondaire** : Blanc (#FFFFFF)
- **Accent** : Gradient violet vers magenta
- **Transparence** : Violet avec opacité 75-95%

### **Éléments Visuels**
- **Ombres** : Effets de profondeur modernes
- **Coins arrondis** : 8-25px selon le contexte
- **Gradients** : Effets visuels sophistiqués
- **Animations** : Transitions fluides et Lottie

### **Responsive Design**
- **Desktop** : SideBar + AppBar + Contenu principal
- **Mobile** : AppBar + Contenu + BottomBar + Drawer
- **Tablette** : Adaptation automatique

## 🚀 **Fonctionnalités Avancées**

### **Drawer Mobile**
- **Fond transparent violet** : Opacité 75%
- **Header avec logo** : Même design que la SideBar
- **Navigation fluide** : 5 options principales
- **Fermeture intuitive** : Bouton X ou tap extérieur

### **BottomBar Mobile**
- **Design moderne** : Fond violet avec coins arrondis
- **Ombres élégantes** : Effet d'élévation
- **Icônes blanches** : Contraste parfait
- **Navigation rapide** : 4 éléments + menu

### **SideBar Desktop**
- **Pleine hauteur** : Depuis le haut de l'écran
- **Logo en haut** : Positionné au-dessus de l'AppBar
- **Navigation complète** : Tous les éléments selon le rôle
- **Ombres à droite** : Effet de séparation

## 📋 **Commandes de Développement**

```bash
# Analyse du code
flutter analyze

# Tests
flutter test

# Build pour production
flutter build windows
flutter build apk
flutter build ios
flutter build web

# Nettoyage
flutter clean
flutter pub get
```

## 🔄 **Workflow de Développement**

1. **Backend** : Modèles → Contrôleurs → Routes → Tests
2. **Frontend** : Services → Contrôleurs → Screens → Tests
3. **Intégration** : Test complet frontend/backend
4. **Documentation** : Mise à jour des README

## 📝 **Logs et Debug**

### **Niveaux de Log**
- **SCREEN** : Actions utilisateur
- **CONTROLLER** : Logique métier
- **SERVICE** : Communication API
- **LAYOUT** : Navigation et layout
- **AUTH** : Authentification

### **Format des Logs**
```
[NIVEAU][Classe] Message descriptif
```

## 🎯 **Prochaines Étapes**

- [ ] Implémentation des écrans métier
- [ ] Intégration SQLite pour cache local
- [ ] Tests unitaires et d'intégration
- [ ] Optimisation des performances
- [ ] Support multilingue complet

## 🆕 **Principales évolutions récentes (2025)**

- **Gestion du magasin courant** : Le magasin sélectionné est sauvegardé dans les SharedPreferences et restauré automatiquement à chaque build. La sélection est propagée à tous les écrans concernés (stocks, produits, etc.).
- **Ajustement de stock après ajout de produit** : Après la création d’un produit, un modal d’ajustement de stock s’ouvre automatiquement pour le magasin courant (sauf si "Tous" est sélectionné, ce qui est interdit pour les ajustements).
- **Filtrage des produits actifs** : Seuls les produits avec `isActive=true` sont affichés dans les listes. La suppression d’un produit est logique (désactivation).
- **Logs détaillés** : Ajout de logs à chaque étape importante : sélection de magasin, chargement des données, création/ajustement de produit, gestion des erreurs, etc. Format `[NIVEAU][Classe] Message` respecté.
- **Gestion stricte du magasin "Tous"** : Il est impossible d’ajuster le stock sur le magasin "Tous" (ce n’est pas un vrai magasin en base).
- **Harmonisation des tables** : La colonne "Produit" affiche désormais le nom du produit (champ `name`). Les alertes de stock sont toujours cohérentes, même pour "Tous".
- **Gestion des erreurs API** : Les erreurs (ex : 500, Cast to ObjectId failed, duplicate key) sont interceptées et affichées à l’utilisateur avec des messages clairs.
- **Cohérence avec le backend** : Les méthodes attendent le retour de l’objet créé (ex : produit avec son ID) pour enchaîner les actions (ajustement, affichage, etc.).
- **Conventions de logs frontend** : Respect des niveaux (SCREEN, CONTROLLER, SERVICE, LAYOUT, AUTH) et du format `[NIVEAU][Classe] Message`.

---

**Note** : Ce projet suit les règles définies dans `CURSOR_RULES.md` pour maintenir la cohérence et la qualité du code. 