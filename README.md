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
L'entièreté de cette section a été effectuée sur Excel.

### 1. Standardiser le nom des produits

Dans cette section, le but majeur est d'avoir le même format pour chaque produit, sans espace, sans majuscule, afin qu'elle soit standardisée et utilisable. Pour atteindre cet objectif,
- J'ai utilisé la fonction UNIQUE() pour faire ressortir chaque nom de produit identifié dans ma colonne ingrédient.
- Manuellement, j'associe, dans un tableau de correspondance, la bonne orthographe à chaque nom identifié dans l'étape précédente.
- j'utilise la fonction XLOOKUP() pour créer une nouvelle colonne avec les noms des produits standardisés.

### 2. Hommogénéiser les prix 

L'objectif ici est d'associer le bon prix au bon produit en remplissant les cases vides et en corrigeant les prix mal enregistrés. Pour ce faire : 
- j'ai fait un tableau de référence avec les noms standardisés et les bons prix unitaires de chaque item.
- utiliser la fonction XLOOKUP() pour créer la nouvelle colonne avec les bons prix.

### 3. Hommogénéiser les quantités

Ici, on cherche à combler les cases vides dans la section quantité de notre base de données : 
- Prendre le Mode de chaque produit, la fréquence le plus achetée par produit sur l'année 2024.
- Avec une fonction IF() combiné à la fonction XLOOKUP() je viens remplir les cases blanches par le mode associer au produit. 

## 📊 Résultats Clés et visualisation 

### 1. Analyse des foodcosts 
L'analyse effectuée dans cette est le premier plan du scene plus profonde, apres avoir mis en lumière les variations de la propention du chiffre d'affaire allouée à l'achat de matiere premiere (graphique 1) 

<img width="521" height="290" alt="image" src="https://github.com/user-attachments/assets/03d3b840-11a3-4ef1-9625-bab9764a8701" />

On remarque que Les varations du ratio foodcost peuvent être expliquées seulement par les variations du chiffre d'affaire mensuel.
Les food cost sont significativement stable dans le temps, entre 5k et 7k. Ainsi les augmentations du ratio est du intuitivement à une baisse du chiffre d'affaire. 

<img width="607" height="292" alt="image" src="https://github.com/user-attachments/assets/f41cee48-b059-422c-a911-031932aebf47" />

Cependant, une analyse detaillée des ventes de chaque produit nous montre que certains ajustements, dans la livraison des ingrédients, sont possible et nécessaire dans la messure où les ventes ne sont pas constantes dans le temps et donc les foodcost sont adaptable. Le tableau ci-dessous montre la differnece de vente entre chaque mois. 

<img width="652" height="282" alt="image" src="https://github.com/user-attachments/assets/35c36c9a-0a56-422f-b689-3b831655e066" />

### 2. Corrélation Coût / Vente

Une analyse graphique du ratio coût/vente et de la fonction de corrélation croisée (CCF sur le logiciel R) révèle que les coûts et les ventes **ne sont pas corrélés de façon contemporaine**. Après la reconstitution de l'inventaire pour identifier la consommation de matières premières du restaurant, on constate un désalignement total entre les commandes d'ingrédients et les ventes au deux semaine.

<img width="1484" height="460" alt="image" src="https://github.com/user-attachments/assets/1eb60ad3-7577-4231-9ebb-f0147fc39f7f" />



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
<img width="1160" height="70" alt="image" src="https://github.com/user-attachments/assets/ecd45e08-546a-4026-9027-ac69983741d5" />

### 3. Régressions par Produit

Pour chaque produit, la relation entre les ventes individuelles et la consommation totale est modélisée :

```r
ventes_produit ~ conso_totale
```

Les intervalles de confiance sont fournis pour chaque prédiction, permettant au gestionnaire de définir une fourchette de commande prudente.

<img width="798" height="337" alt="image" src="https://github.com/user-attachments/assets/74c57856-47d5-4ae8-9e5c-89ccb70066d3" />

---

## 📂 Description des Données

 L'intégraliter de mes jeux de données sont générés par l'intelligence artificielle Claude, ce qui pousse mon annalyse à être incomplete, il m'a été compliqué de tirer des conclusions solides mais les objectifs ici étaient d'oppérer un travail de nétoyage, d'analyse et de modélisation cohérents. 
**Feuilles Excel principales :**
- `donnees_brutes_restaurant` — Données POS brutes (ID_Commande, Date, Heure, Zone, Serveur, Produit, Quantité, Prix_Unitaire)
- `factures_fournisseurs_brut` — Données POS brutes ( ID_Facture, Date, Fournisseur, Ingrédient, Quantite_Livree, Unite, Prix_Unitaire_HT)

---

## 👤 Auteur

Étudiant en sciences économiques à l'universté de Montréal, je cherche a développer mes compétences via la création d'un portfolio.
Ce Projet est réalisé dans le cadre d'une analyse de gestion de restaurant fictif.

---

## 📄 Licence

Ce projet est à usage éducatif et analytique.
