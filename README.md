# TP SQL - Analyse d'un jeu en ligne

Projet analytique en groupe (SQL avancé, PostgreSQL). Thème : un jeu en ligne avec des joueurs, des parties, des participations et des achats de skins.

## Charger la base

```bash
createdb jeu_en_ligne
psql -d jeu_en_ligne -f schema.sql
psql -d jeu_en_ligne -f seed.sql
psql -d jeu_en_ligne -f requetes.sql
```

## Schéma

```text
joueur (id PK, nom UNIQUE, skin, niveaux, rang)
   |
   |-- amitie (joueur_id FK, ami_id FK)            PK (joueur_id, ami_id)
   |-- achat (id PK, joueur_id FK, skin_perso, skin_arme, montant, date_achat)
   |-- jeux (id PK, joueur_id FK, partie_id FK, date_partie, score, duree_secondes)
                                                   UNIQUE (joueur_id, partie_id)
partie (id PK, categorie_id FK, nb_joueur, mode_de_jeux, created_at)
   |
categorie_niveau (id PK, nom, parent_id FK -> categorie_niveau.id)   <- table hiérarchique
```

- `joueur` est la table principale : contient les profils utilisateurs (nom unique, skin, niveaux et rang).
   - `amitie` est la table d'association : une table `amitie` (joueur_id, ami_id) remplace l'ancienne colonne texte `amis`, car un joueur peut avoir plusieurs amis.
   - `achat` est la table des transactions : 30 achats, un tous les 3 jours du 04/07 au 29/09, pour couvrir les trois mois.
   - `jeux` est la table d'événements : 150 participations du 01/07 au 30/09/2026 (score et durée).

- `partie` est la table des sessions de jeu : 20 parties enregistrées avec au maximum 10 joueurs (modes solo, duo ou équipe), avec une partie générée par jour.
- `categorie_niveau` est la table hiérarchique : 3 catégories racines (Debutant, Intermediaire, Expert) avec 4 sous-niveaux chacune.

## Volumes

| Table | Lignes |
|---|---|
| joueur | 20 |
| amitie | 20 |
| categorie_niveau | 15 |
| partie | 20 |
| jeux | 150 |
| achat | 30 |

## Fichiers

- `schema.sql` : création des tables.
- `seed.sql` : insertion des données (générées avec `generate_series` et `setseed(0.42)`).
- `requetes.sql` : vérifications du palier 1 et requêtes Q1 à Q16, chacune précédée de sa question métier.
- `JOURNAL.md` : choix faits, ce que chaque requête apprend, difficultés.

## Requêtes

| Palier | Requêtes | Techniques |
|---|---|---|
| 1 | Vérifications | comptages, période, hiérarchie |
| 2 | Q1 à Q7 | `RANK`, `ROW_NUMBER` + CTE, `SUM OVER`, `LAG`, part du total, `ROWS BETWEEN`, `AVG OVER PARTITION BY` |
| 3 | Q8 à Q12 | CTE enchaînées, `WITH RECURSIVE` (arbre et total par branche), `generate_series` + `LEFT JOIN` |
| 4 | Q13 à Q16 | `FILTER`, `ROLLUP` + `GROUPING`, `percentile_cont`, tableau de bord |
| 5 (Bonus) | Q 17 et Q18 | optimisation du coût et raccourci`EXPLAIN ANALYZE` + `CREATE VIEW`|