# JOURNAL

Thème : jeu en ligne (joueurs, parties, participations, achats).

## Choix faits

- **Table d'événements** : `jeux` (une ligne = la participation d'un joueur à une partie), avec une date, un score et une durée. 150 lignes réparties du 01/07 au 30/09/2026, avec des participations pour les 20 joueurs.
- **Table hiérarchique** : `categorie_niveau`, 2 niveaux (3 catégories racines Debutant, Intermediaire, Expert, chacune avec 4 sous-niveaux). Chaque partie est rattachée à l'une des 15 catégories.
- **Amitiés** : une table `amitie` (joueur_id, ami_id) remplace l'ancienne colonne texte `amis`, car un joueur peut avoir plusieurs amis.
- **Données reproductibles** : `setseed(0.42)` donne toujours les mêmes valeurs aléatoires pour les scores et les durées.
- **Achats** : 30 achats, un tous les 3 jours du 04/07 au 29/09, pour couvrir les trois mois.
- **Données aléatoires** : le score et la durée sont tirés au hasard, sans lien avec le rang ou le niveau du joueur.

## Palier 2 : ce que chaque requête nous apprend

| Requête | Ce qu'elle apprend sur nos données |
|---|---|
| Q1 : classement par rang (`RANK`) | Le rang affiché ne prédit pas le score total : le meilleur Bronze (joueur_8 : 25 881) dépasse le meilleur Diamant (joueur_19 : 24 994). |
| Q2 : top 3 par mode de jeu (`ROW_NUMBER` + CTE) | Chaque mode a un top 3 différent (joueur_8 en Duo, joueur_10 en Equipe, joueur_16 en Solo), mais certains joueurs n'ont qu'une ou deux parties dans un mode (joueur_16 : une seule en Solo), donc le classement est fragile. |
| Q3 : CA cumulé (`SUM OVER`) | Le CA augmente chaque mois (105 €, 205 €, 305 €) et atteint 615 € au total. |
| Q4 : évolution hebdomadaire (`LAG`) | Le CA par semaine est irrégulier (de -47,8 % à +150 %), et la première et la dernière semaine sont partielles, ce qui fausse leur comparaison. |
| Q5 : part du CA par skin (`SUM OVER ()`) | Le skin Robot rapporte le plus (27,3 % du CA) et le skin Fantome le moins (22,8 %), des écarts modérés. |
| Q6 : moyenne mobile 7 jours (`ROWS BETWEEN`) | Le score moyen reste entre environ 1 400 et 3 700 sans tendance nette : la moyenne mobile lisse les variations mais ne révèle pas de progression. |
| Q7 : écart à la moyenne du rang (`AVG OVER PARTITION BY`) | joueur_19 est le plus au-dessus de son rang Diamant (+942) et joueur_12 le plus en dessous de son rang Bronze (-671), donc le rang affiché ne reflète pas le niveau réel de jeu. |

## Palier 3 : ce que chaque requête nous apprend

| Requête | Ce qu'elle apprend sur nos données |
|---|---|
| Q8 : joueurs au-dessus de la moyenne (2 CTE) | 9 joueurs sur 20 dépassent la moyenne de 19 556 points ; joueur_8 est en tête avec 25 881 points. |
| Q9 : gros acheteurs et durée de jeu (3 CTE) | Dépenser plus ne veut pas dire jouer plus longtemps : joueur_8 dépense 46 € mais joue 22,3 min par partie, alors que joueur_5 dépense 40 € et joue 39,8 min. |
| Q10 : arbre des catégories (`WITH RECURSIVE`) | Les 15 catégories forment 3 branches (Debutant, Intermediaire, Expert) de 5 éléments chacune. |
| Q11 : total par branche (`WITH RECURSIVE`) | Les branches Expert (53 participations) et Intermediaire (52) pèsent presque autant, Debutant (45) un peu moins. |
| Q12 : jours sans achat (`generate_series` + `LEFT JOIN`) | 62 jours sur 92 n'ont aucun achat, car il n'y a qu'un achat tous les 3 jours environ. |

## Palier 4 : ce que chaque requête nous apprend

| Requête | Ce qu'elle apprend sur nos données |
|---|---|
| Q13 : CA par skin et par mois (`FILTER`) | Le CA de chaque skin augmente de juillet à septembre ; Robot reste en tête sur le total (168 €). |
| Q14 : participations par mode et rang (`ROLLUP`) | Les trois modes ont un volume proche (Duo 52, Equipe 53, Solo 45 sur 150), mais le score moyen varie : 2 711 en Equipe contre 2 402 en Solo. |
| Q15 : moyenne contre médiane (`percentile_cont`) | Moyenne 31,1 min et médiane 31,0 min : presque identiques. |
| Q16 : tableau de bord mensuel (CTE + `SUM OVER` + `LAG`) | L'activité de jeu est stable (48 à 51 participations, 20 joueurs actifs chaque mois) alors que le CA progresse (+95,2 % en août, +48,8 % en septembre). |

**Moyenne contre médiane** : les durées sont tirées uniformément entre 1 et 60 minutes, donc la distribution est symétrique et la moyenne (31,1 min) représente aussi bien nos données que la médiane (31,0 min). Avec des durées très asymétriques (beaucoup de parties courtes, quelques très longues), la médiane serait plus fiable, car la moyenne serait tirée vers le haut par les parties longues.

## Difficultés rencontrées

Le schéma et les requêtes n'étaient pas synchronisés : la colonne s'appelait `rank` dans le schéma mais `rang` dans les requêtes, et la table `amitie` n'existait pas. En rechargeant la base depuis zéro (`schema.sql` puis `seed.sql`) et en lançant toutes les requêtes, nous avons trouvé les erreurs. Nous avons aussi vu que seuls 8 joueurs sur 20 avaient des participations, ce qui rendait les classements pauvres : nous avons corrigé la génération des données. Nous referions un test complet de rechargement à chaque modification.