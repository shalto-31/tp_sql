# JOURNAL

Thème : jeu en ligne (joueurs, parties, participations, achats).

## Choix faits

- **Table d'événements** : `jeux` (une ligne = la participation d'un joueur à une partie), avec une date, un score et une durée. Elle contient 180 lignes réparties du 01/07 au 30/09/2026.
- **Table hiérarchique** : `categorie_niveau`, avec 3 niveaux de profondeur (par exemple Expert > Classe competitive > Ligue Diamant). Chaque partie est rattachée à une catégorie « feuille ».
- **Amitiés** : une table `amitie` remplace l'ancienne colonne texte `amis`, car un joueur peut avoir plusieurs amis.
- **Données reproductibles** : `setseed(0.42)` donne toujours les mêmes valeurs aléatoires.
- **Cohérence des données** : la date d'une participation est celle de sa partie, et `nb_joueur` correspond au vrai nombre de participants.
- **Durées asymétriques** : `power(random(), 3)` crée beaucoup de parties courtes et quelques longues, pour que la moyenne et la médiane soient différentes (palier 4).
- **Score lié au niveau** : le score augmente avec le niveau du joueur, ce qui rend les classements par rang plus réalistes.

## Palier 2 : ce que chaque requête nous apprend

| Requête | Ce qu'elle apprend sur nos données |
|---|---|
| Q1 : classement par rang (`RANK`) | Les meilleurs joueurs Diamant et Or (joueur_8 : 41 571 points, joueur_15 : 34 912) dépassent largement le meilleur Bronze (joueur_14 : 20 574), mais le score total mélange niveau et nombre de parties jouées. |
| Q2 : top 3 par mode de jeu (`ROW_NUMBER` + CTE) | Chaque mode a un top 3 différent (joueur_15 en Duo, joueur_16 en Equipe, joueur_13 en Solo), mais certains joueurs ont très peu de parties dans un mode (joueur_17 n'en a qu'une en Solo), donc le classement est fragile. |
| Q3 : CA cumulé (`SUM OVER`) | Le CA est stable d'un mois à l'autre (330 €, 261 €, 317 €) et atteint 907,40 € au total, avec un creux en août. |
| Q4 : évolution hebdomadaire (`LAG`) | Le CA par semaine est très irrégulier (de -76 % à +232 %), et la première et la dernière semaine sont partielles, ce qui fausse leur comparaison. |
| Q5 : part du CA par skin (`SUM OVER ()`) | Le skin Fantome rapporte le plus (30,5 % du CA) et le skin Dragon le moins (18,1 %), mais les écarts restent modérés. |
| Q6 : moyenne mobile 7 jours (`ROWS BETWEEN`) | Le score moyen reste entre 2 000 et 2 800 jusqu'à mi-septembre, puis monte au-dessus de 3 000 en fin de mois. |
| Q7 : écart à la moyenne du rang (`AVG OVER PARTITION BY`) | joueur_4 est le plus au-dessus de son rang Argent (+559) et joueur_2 le plus en dessous de son rang Diamant (-552), donc le rang affiché ne reflète pas toujours le niveau réel de jeu. |
| Q8 : joueurs au-dessus de la moyenne (2 CTE) | 5 joueurs sur 20 dépassent la moyenne de 48 890 points ; joueur_3 est en tête avec 60 018 points. |
| Q9 : gros acheteurs et durée de jeu (3 CTE) | Dépenser plus ne veut pas dire jouer plus longtemps : joueur_4 dépense 38 € et joue 37,7 min par partie en moyenne, joueur_8 dépense 46 € mais joue seulement 28,3 min. |
| Q10 : arbre des catégories (`WITH RECURSIVE`) | Les 15 catégories forment 3 branches (Debutant, Intermediaire, Expert) de 5 éléments chacune. |
| Q11 : total par branche (`WITH RECURSIVE`) | Les branches Intermediaire (53 participations) et Expert (52) pèsent presque autant, Debutant (45) un peu moins. |
| Q12 : jours sans achat (`generate_series` + `LEFT JOIN`) | 62 jours sur 92 n'ont aucun achat, car les achats ne se produisent que tous les 2 jours en juillet-août, puis plus du tout en septembre. |
## Difficultés rencontrées

*(à compléter par le groupe : une difficulté réelle, comment vous l'avez résolue, ce que vous referiez autrement)*

## Palier 3 : CTE et récursivité

*(à compléter)*

## Palier 4 : rapport d'agrégation

*(à compléter, dont la phrase d'interprétation moyenne contre médiane : quelle valeur représente le mieux les durées de parties, et pourquoi ?)*