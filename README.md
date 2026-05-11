# 🍕 Optimisation des Food Costs — Analyse & Prédiction de Consommation

> Analyse des ventes et des coûts d'un restaurant fictif (5 produits) avec modélisation prédictive des consommations sur 2 semaines via R.

---

## 📌 Contexte du Projet

Ce projet simule l'environnement d'un restaurant proposant 5 produits :

| Produit | Prix unitaire |
|---|---|
| Pizza Margarita | 12,00 $ |
| Kebab | 8,50 $ |
| Burger | 10,00 $ |
| Coca-Cola | 2,50 $ |
| 7up | 2,50 $ |

L'objectif est d'**optimiser le food cost** et anticiper les consommations futures afin d'ajuster les commandes de matières premières et de réduire les pertes.

---

## 🎯 Objectifs

1. **Nettoyage des données** — Standardiser les ventes brutes et les coûts bruts issues du POS (casses, espaces, doublons produits)
2. **Analyse descriptive** — Étudier les ventes quotidiennes, le ratio coût/vente et les tendances par produit
3. **Diagnostic de non-corrélation** — Identifier pourquoi les coûts ne suivent pas les ventes à court terme
4. **Modèle prédictif** — Prédire la consommation totale des 2 prochaines semaines (saisonnalité + historique glissant)
5. **Prédiction par produit** — Ventiler la consommation totale prédite sur chacun des 5 produits

---

## 📁 Structure du Projet

```
food-cost-optimisation/
│
├── data/
│   └── Factures_fournisseurs_brut    # Registre des commandes effectuer sur l'annnée 2024
│   └── Donnees_brutes_restaurant     # Les vente du restaurant sur l'année 2024
│   └── Food_cost_analyse.xlsx        # Données sources (ventes brutes + ventes ajustées + coûts + coûts ajusté )
│   └── README_data.md                # Description des colonnes et des feuilles Excel
│
├── scripts/
│   └── Analyse_econometrique.R       # Script R complet (nettoyage → analyse → prédiction)
│
├── outputs/
│   └── (graphiques générés par R)
│
├── docs/
│   └── methodologie.md               # Détail des choix méthodologiques
│
├── .gitignore
└── README.md
```

---

## 🔄 Pipeline d'Analyse

```
Ventes Brutes (Excel)
        │
        ▼
  Nettoyage & Standardisation des produits
        │
        ▼
  Agrégation Quotidienne (Ventes + Coûts)
        │
        ▼
  Analyse descriptive + Corrélation Coût/Vente
        │
        ▼
  Détection de la non-corrélation contemporaine
  → Les coûts reflètent les commandes (t-2 semaines),
    pas les ventes immédiates
        │
        ▼
  Modèle ML : Régression linéaire multivariée
  Y = Consommation sur les 2 prochaines semaines
  X1 = Moyenne glissante 14j de la consommation passée
  X2 = Saison (Hiver / Printemps / Été / Automne)
        │
        ▼
  Prédiction par produit via régression individuelle
  (Margarita, Burger, Kebab, Coca, 7up)
```

---

## 🛠️ Technologies

- **R** — Langage principal
- **dplyr** — Manipulation de données
- **ggplot2** — Visualisations
- **fixest** — Régressions économétriques
- **lubridate** — Gestion des dates
- **slider** — Moyennes glissantes (rolling windows)
- **readxl** — Import des données Excel

---

## Nétoyage des données
L'entrieter de cette section a été effectuée sur Excel

### 1. Standardisé le nom des produits

Dans cette section, le but majeur est d'avoir le même format pour chauque produit, sans espace, sans majuscule, afin que elle soit standardisé et utilisable. Pour atteindre cette objectif,
1 J'ai utilisé la fonction UNIQUE() pour faire resortir chaque nom de produit identifier dans ma colonne ingredient.
2 Manuellemant j'assosie ,dans un tableau de correspondance, la bonne ortigraphe à chaque nom identifié dans l'étape précédante.
3 j'utiliser la fonction XLOOKUP pour créer une nouvelle colonne avec les noms des produits standarisés.

### 2. Hommogénéiser les prix 

L'objetif ici est d'assossier le bon prix au bon produit en remplissant les cases vides et en corrigeant les prix mal enregistrer. Pour ce faire: 
1 j'ai fait un tableau de reférence avec les noms standardisés et les bon prix unitaire de chaque item.
2 utiliser la fonction XLOOKUP() pour créer la nouvelle colonne avec les bons prix

## 📊 Résultats Clés

### 1. Corrélation Coût / Vente

Une analyse graphique du ratio coût/vente et de la fonction de corrélation croisée (CCF) révèle que les coûts et les ventes **ne sont pas corrélés de façon contemporaine**. Après la reconstitution de l'inventaire pour identifier la consommation de matières premières du restaurant, on constate un désalignement total entre les commandes d'ingrédients et les ventes.

L'explication structurelle est que les commandes fournisseurs et les ventes sont générées par intelligence artificielle et ne proviennent pas d'un restaurant réel — les coûts de la semaine `t` ne correspondent donc pas aux ventes anticipées de `t+2`. Suite à cette observation, j'ai décidé d'ignorer les commandes de matières premières et d'utiliser uniquement le fichier des ventes pour entraîner un modèle dans le but de prédire la consommation totale en unités sur deux semaines, afin de déterminer les quantités précises à commander à la semaine `t`.

### 2. Modèle de Consommation (2 semaines)

Le modèle retenu est une régression linéaire de la forme :

```
Y_consommation_future ~ X1_consommation_passe + saison
```

Où :
- `Y` = somme des commandes sur les 14 jours suivants
- `X1` = moyenne glissante sur les 14 derniers jours
- `saison` = variable catégorielle (Hiver / Printemps / Été / Automne)

**Exemple de prédiction :** Pour une consommation passée de 135 unités/jour en Printemps, le modèle estime une consommation totale sur 2 semaines, ensuite ventilée sur chaque produit via des régressions individuelles.

### 3. Régressions par Produit

Pour chaque produit, la relation entre les ventes individuelles et la consommation totale est modélisée :

```r
ventes_produit ~ conso_totale
```

Les intervalles de confiance sont fournis pour chaque prédiction, permettant au gestionnaire de définir une fourchette de commande prudente.

---

## 🚀 Lancer le Projet

### Prérequis

```r
install.packages(c("dplyr", "fixest", "ggplot2", "readxl", "lubridate", "slider"))
```

### Exécution

1. Cloner le dépôt
2. Ouvrir `scripts/Analyse_econometrique.R` dans RStudio
3. Mettre à jour les chemins de fichiers en tête de script :
   ```r
   cout_restaurant <- read_excel("data/Food_cost_analyse.xlsx", sheet = "Coûts", ...)
   Ventes_ajustes  <- read_excel("data/Food_cost_analyse.xlsx", sheet = "Ventes ajustées", ...)
   ```
4. Exécuter le script séquentiellement (Ctrl+Alt+R dans RStudio)

---

## 📂 Description des Données

Voir [`data/README_data.md`](data/README_data.md) pour le dictionnaire complet des variables.

**Feuilles Excel principales :**
- `Ventes Brutes` — Données POS brutes (ID_Commande, Date, Heure, Zone, Serveur, Produit, Quantité, Prix_Unitaire)
- `Ventes ajustées` — Données nettoyées avec `Produit standardisé` et `Ventes` calculées
- Données coûts — Coûts journaliers des ingrédients par date

---

## 📖 Méthodologie

Voir [`docs/methodologie.md`](docs/methodologie.md) pour le détail des choix de modélisation.

---

## 👤 Auteur

Projet réalisé dans le cadre d'une analyse de gestion de restaurant fictif.

---

## 📄 Licence

Ce projet est à usage éducatif et analytique.
