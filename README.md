# TP SQL - Analyse d'un jeu en ligne

## Présentation

Ce projet a pour objectif d'explorer, valider et analyser les données d'un jeu en ligne à l'aide de SQL avancé. Il s'inscrit dans un contexte pédagogique où l'on manipule des tables relationnelles, des données de jeu, des achats, des niveaux hiérarchiques et des événements de participation.

Le travail s'articule autour de trois grands axes :

- la vérification de la cohérence de la base de données ;
- l'analyse statistique avec les fonctions de fenêtre ;
- l'utilisation des requêtes récursives et des CTE pour modéliser des hiérarchies et des agrégations complexes.

> Ce document couvre les paliers 1, 2 et 3. Les paliers 4 et 5 ne sont pas détaillés dans ce README.

---

## 1. Contexte métier

Le jeu en ligne comprend plusieurs éléments :

- des joueurs avec un rang et des niveaux de progression ;
- des catégories hiérarchiques représentant les niveaux de jeu ;
- des parties associées à un mode de jeu et à une catégorie ;
- des participations de joueurs à ces parties ;
- des achats d'objets cosmétiques effectués par les utilisateurs.

L'objectif est d'étudier les performances, les achats et la structure du jeu pour en tirer des indicateurs utiles à l'analyse de la plateforme.

---

## 2. Modèle de données

Le schéma contient les tables suivantes :

- joueur : informations sur les joueurs, leur rang et leur niveau ;
- categorie_niveau : hiérarchie des niveaux et sous-niveaux ;
- partie : descriptions des parties et de leur mode de jeu ;
- jeux : table d'événements, qui représente chaque participation d'un joueur à une partie ;
- achat : achats de skins et accessoires effectués par les joueurs.

### Structure générale

- Un joueur peut participer à plusieurs parties.
- Une partie appartient à une catégorie précise.
- Un joueur peut effectuer plusieurs achats.
- Les catégories de niveau peuvent être organisées de manière hiérarchique.

---

## 3. Objectifs du TP

Le TP vise à développer des compétences SQL avancées, notamment :

- la vérification de la qualité des données ;
- la mise en œuvre de fonctions analytiques ;
- l'agrégation de données sur des périodes ;
- l'exploitation de requêtes récursives pour parcourir des arbres hiérarchiques ;
- la construction de logique analytique avec des CTE.

---

## 4. Palier 1 - Vérification et cohérence de la base

Le premier palier consiste à contrôler que la base est bien alimentée et cohérente. Il s'agit de vérifier les volumes de données, les dates couvertes et la structure de la hiérarchie.

### Vérifications principales

Les requêtes de ce palier permettent de valider :

- le nombre de lignes par table ;
- la période de couverture des données ;
- la présence des catégories parentes et enfants ;
- la structure de la table hiérarchique.

### Ce que l'on vérifie

- que chaque table contient bien le bon nombre d'enregistrements ;
- que les événements sont répartis sur plusieurs mois ;
- que la table de catégories est correctement reliée à elle-même ;
- que les relations entre les tables restent cohérentes.

### Exemple de logique de contrôle

- comptage des lignes par table ;
- calcul de la date minimale et maximale des participations ;
- affichage des catégories avec leur parent direct.

Cette étape est essentielle avant toute exploitation analytique, car elle permet d'éviter de travailler sur des données incomplètes ou mal structurées.

---

## 5. Palier 2 - Fonctions de fenêtre

Le deuxième palier met en œuvre les fonctions de fenêtre SQL, qui permettent d'effectuer des calculs sur un ensemble de lignes sans perdre la granularité des données.

### Les objectifs analytiques

Les requêtes du palier 2 permettent de répondre à des questions comme :

- comment classer les joueurs par rang selon leur score total ?
- quels sont les meilleurs joueurs par mode de jeu ?
- quel est le chiffre d'affaires cumulé mois par mois ?
- quelle est l'évolution du chiffre d'affaires d'une semaine à l'autre ?
- quelle part du CA représente chaque skin ?
- comment les scores évoluent-ils sur plusieurs jours ?
- quel est l'écart d'un joueur par rapport à la moyenne de son rang ?

### Fonctionnement des requêtes

Les principales fonctions utilisées sont :

- RANK() : classement par rang avec gestion des égalités ;
- ROW_NUMBER() : attribution d'un numéro unique à chaque ligne ;
- SUM() OVER() : cumul de valeurs sur une fenêtre ;
- LAG() : récupération de la valeur précédente ;
- AVG() OVER() : calcul de moyennes sur des partitions ou sur des fenêtres successives.

### Intérêt pédagogique

Ce palier permet de passer d'une agrégation classique à une analyse plus fine, en donnant accès à des indicateurs dynamiques : cumuls, tendances, positions relatives et évolutions temporelles.

---

## 6. Palier 3 - CTE et récursivité

Le troisième palier introduit la notion de Common Table Expressions (CTE) ainsi que les requêtes récursives. Ces outils sont particulièrement utiles pour traiter des hiérarchies, calculer des sous-ensembles et enchaîner plusieurs étapes de transformation logique.
## 7. palier 4 -

## 8. palier 5 -

### Objectifs principaux

Les requêtes de ce palier répondent à des questions telles que :
 
- quels joueurs dépassent la moyenne générale des scores ?
- quels gros acheteurs jouent le plus longtemps en moyenne ?
- quelle est l'arborescence complète des catégories de niveau ?
- combien de participations et de points chaque branche de la hiérarchie regroupe-t-elle ?
- quels sont les jours où aucun achat n'a eu lieu ?

### Utilisation des CTE

Les CTE permettent :

- d'écrire des calculs intermédiaires de manière lisible ;
- d'enchaîner plusieurs transformations sans rendre la requête illisible ;
- de préparer les données avant un filtrage ou une agrégation finale.

### Récursivité

Les requêtes récursives sont utilisées pour parcourir les catégories de niveau de manière hiérarchique. Cela permet de calculer :

- le niveau d'une catégorie dans l'arbre ;
- le chemin complet depuis la racine ;
- le total agrégé de chaque branche.

Cette partie est particulièrement importante pour modéliser des structures qui ne sont pas plates, mais organisées selon une logique de parent/enfant.

---

## 7. Arborescence du projet

L'organisation du projet est la suivante :

```text
TP-1/
└── tp_sql/
    ├── README.md
    ├── JOURNAL.md
    ├── schema.sql
    ├── seed.sql
    ├── requetes.sql
    └── tp sql.iml
```

### Description de chaque fichier

- README.md : document principal de présentation du TP, expliquant le contexte, l'organisation du projet et les objectifs des paliers 1 à 3.
- JOURNAL.md : journal de travail du groupe. Il contient les choix techniques, les décisions de modélisation et les observations sur les données.
- schema.sql : défini l'ensemble du schéma relationnel de la base de données, notamment les tables joueur, categorie_niveau, partie, jeux et achat.
- seed.sql : charge les données initiales de démonstration. Il permet de remplir la base avec les joueurs, les parties, les participations et les achats.
- requetes.sql : regroupe toutes les requêtes SQL du TP, du palier 1 jusqu'aux requêtes analytiques des paliers 2 et 3.
- tp sql.iml : fichier de configuration IDE associé au projet, utile pour l'environnement de travail local.

Cette structure permet de séparer clairement la définition du schéma, les données de test et les requêtes d'analyse, ce qui rend le projet plus lisible et plus maintenable.

---

## 8. Méthodologie de travail

Pour exploiter le projet correctement, il est recommandé de suivre l'ordre suivant :

1. créer la base de données ;
2. exécuter schema.sql ;
3. exécuter seed.sql ;
4. lancer les requêtes de vérification ;
5. analyser les résultats du palier 2 ;
6. utiliser les CTE et la récursivité du palier 3 ;
7. interpréter les résultats de manière analytique.

---

## 9. Conclusion

Ce TP permet de mettre en pratique des compétences SQL avancées dans un cadre concret et réaliste. Il couvre les principes fondamentaux de la validation de données, de l'analyse par fenêtre et de la modélisation de hiérarchies récursives.

L'objectif est non seulement d'écrire des requêtes correctes, mais aussi de comprendre ce que ces requêtes révèlent sur le comportement des joueurs, la structure du jeu et l'évolution de ses activités commerciales.

---

## 10. Remarques

Le présent README a été conçu pour présenter de manière claire et professionnelle les paliers 1 à 3 du TP. Les paliers 4 et 5 ne sont pas inclus dans ce document afin de rester concentré sur la base analytique et technique du projet.
