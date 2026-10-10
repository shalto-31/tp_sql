-- Palier 1 : nombre de lignes par table
SELECT 'joueur' AS table_nom, COUNT(*) FROM joueur
UNION ALL SELECT 'amitie', COUNT(*) FROM amitie
UNION ALL SELECT 'categorie_niveau', COUNT(*) FROM categorie_niveau
UNION ALL SELECT 'partie', COUNT(*) FROM partie
UNION ALL SELECT 'jeux', COUNT(*) FROM jeux
UNION ALL SELECT 'achat', COUNT(*) FROM achat;

-- Palier 1 : période couverte par la table d'événements
SELECT COUNT(*) AS nombre_evenements,
       MIN(date_partie) AS premiere_date,
       MAX(date_partie) AS derniere_date
FROM jeux;

-- Palier 1 : table hiérarchique, chaque catégorie avec son parent
SELECT enfant.nom AS categorie, parent.nom AS categorie_parente
FROM categorie_niveau AS enfant
LEFT JOIN categorie_niveau AS parent ON enfant.parent_id = parent.id
ORDER BY parent.id NULLS FIRST, enfant.id;

-- Q1 : Dans chaque rang (Bronze, Argent, Or, Diamant), comment se classent
--      les joueurs selon leur score total ?
-- Fonction : RANK() avec PARTITION BY
SELECT j.rang,
       j.nom,
       SUM(e.score) AS score_total,
       RANK() OVER (PARTITION BY j.rang ORDER BY SUM(e.score) DESC) AS place_dans_le_rang
FROM joueur AS j
JOIN jeux AS e ON e.joueur_id = j.id
GROUP BY j.id, j.rang, j.nom
ORDER BY CASE j.rang WHEN 'Bronze' THEN 1 WHEN 'Argent' THEN 2
                     WHEN 'Or' THEN 3 ELSE 4 END,
         place_dans_le_rang;

-- Q2 : Quels sont les 3 meilleurs joueurs (score moyen par partie) dans
--      chaque mode de jeu (Solo, Duo, Equipe) ?
-- Fonction : ROW_NUMBER() avec PARTITION BY, dans une CTE
WITH score_par_mode AS (
    SELECT p.mode_de_jeux,
           j.nom,
           ROUND(AVG(e.score), 0) AS score_moyen,
           COUNT(*) AS nb_parties
    FROM jeux AS e
    JOIN joueur AS j ON j.id = e.joueur_id
    JOIN partie AS p ON p.id = e.partie_id
    GROUP BY p.mode_de_jeux, j.id, j.nom
),
classement AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY mode_de_jeux
                              ORDER BY score_moyen DESC, nom) AS position
    FROM score_par_mode
)
SELECT mode_de_jeux, position, nom, score_moyen, nb_parties
FROM classement
WHERE position <= 3
ORDER BY mode_de_jeux, position;

-- Q3 : Quel est le chiffre d'affaires cumulé des achats, mois après mois ?
-- Fonction : SUM() OVER (ORDER BY ...)
WITH ca_mensuel AS (
    SELECT date_trunc('month', date_achat)::date AS mois,
           SUM(montant) AS ca
    FROM achat
    GROUP BY 1
)
SELECT mois,
       ca,
       SUM(ca) OVER (ORDER BY mois) AS ca_cumule
FROM ca_mensuel
ORDER BY mois;

-- Q4 : De combien (en %) le chiffre d'affaires évolue-t-il d'une semaine
--      à l'autre ?
-- Fonction : LAG()
WITH ca_hebdo AS (
    SELECT date_trunc('week', date_achat)::date AS semaine,
           SUM(montant) AS ca
    FROM achat
    GROUP BY 1
)
SELECT semaine,
       ca,
       LAG(ca) OVER w AS ca_semaine_precedente,
       ROUND(100.0 * (ca - LAG(ca) OVER w) / NULLIF(LAG(ca) OVER w, 0), 1)
           AS evolution_pct
FROM ca_hebdo
WINDOW w AS (ORDER BY semaine)
ORDER BY semaine;

-- Q5 : Quelle part du chiffre d'affaires total chaque skin de personnage
--      représente-t-il ?
-- Fonction : SUM(...) OVER () (fenêtre sur toutes les lignes)
SELECT skin_perso,
       SUM(montant) AS ca,
       ROUND(100.0 * SUM(montant) / SUM(SUM(montant)) OVER (), 1) AS part_du_ca_pct
FROM achat
GROUP BY skin_perso
ORDER BY ca DESC;

-- Q6 : Comment le score moyen évolue-t-il au fil des jours, en lissant les
--      variations avec une moyenne mobile ?
-- Fonction : AVG() OVER (ORDER BY ... ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
WITH score_par_jour AS (
    SELECT date_partie::date AS jour,
           ROUND(AVG(score), 0) AS score_moyen
    FROM jeux
    GROUP BY 1
)
SELECT jour,
       score_moyen,
       ROUND(AVG(score_moyen) OVER (ORDER BY jour
                                    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 0)
           AS moyenne_mobile_7_jours
FROM score_par_jour
ORDER BY jour;

-- Q7 : Quels joueurs jouent bien au-dessus ou en dessous de la moyenne de
--      leur rang ?
-- Fonction : AVG() OVER (PARTITION BY ...)
WITH score_par_joueur AS (
    SELECT j.nom,
           j.rang,
           ROUND(AVG(e.score), 0) AS score_moyen
    FROM joueur AS j
    JOIN jeux AS e ON e.joueur_id = j.id
    GROUP BY j.id, j.nom, j.rang
)
SELECT rang,
       nom,
       score_moyen,
       ROUND(AVG(score_moyen) OVER (PARTITION BY rang), 0) AS moyenne_du_rang,
       score_moyen - ROUND(AVG(score_moyen) OVER (PARTITION BY rang), 0) AS ecart
FROM score_par_joueur
ORDER BY ecart DESC;

-- Q8 : Quels joueurs ont un score total supérieur à la moyenne des joueurs ?
-- Fonction : 2 CTE enchaînées
WITH score_par_joueur AS (
    SELECT j.id,
           j.nom,
           SUM(e.score) AS score_total
    FROM joueur AS j
    JOIN jeux AS e ON e.joueur_id = j.id
    GROUP BY j.id, j.nom
),
moyenne_generale AS (
    SELECT AVG(score_total) AS moyenne
    FROM score_par_joueur
)
SELECT s.nom,
       s.score_total,
       ROUND(m.moyenne, 0) AS moyenne_des_joueurs,
       s.score_total - ROUND(m.moyenne, 0) AS ecart
FROM score_par_joueur AS s
CROSS JOIN moyenne_generale AS m
WHERE s.score_total > m.moyenne
ORDER BY s.score_total DESC;

-- Q9 : Parmi les gros acheteurs (dépense totale supérieure à la moyenne),
--      lesquels jouent le plus longtemps en moyenne par partie ?
-- Fonction : 3 CTE enchaînées
WITH depense_par_joueur AS (
    SELECT joueur_id,
           SUM(montant) AS depense_totale
    FROM achat
    GROUP BY joueur_id
),
gros_acheteurs AS (
    SELECT joueur_id, depense_totale
    FROM depense_par_joueur
    WHERE depense_totale > (SELECT AVG(depense_totale) FROM depense_par_joueur)
),
duree_par_joueur AS (
    SELECT joueur_id,
           ROUND(AVG(duree_secondes) / 60.0, 1) AS duree_moyenne_minutes,
           COUNT(*) AS nb_parties
    FROM jeux
    GROUP BY joueur_id
)
SELECT j.nom,
       g.depense_totale,
       d.duree_moyenne_minutes,
       d.nb_parties
FROM gros_acheteurs AS g
JOIN joueur AS j ON j.id = g.joueur_id
JOIN duree_par_joueur AS d ON d.joueur_id = g.joueur_id
ORDER BY d.duree_moyenne_minutes DESC;

-- Q10 : Quelle est l'arborescence complète des catégories de niveau, avec
--       le niveau de profondeur et le chemin depuis la racine ?
-- Fonction : WITH RECURSIVE
WITH RECURSIVE arbre AS (
    SELECT id,
           nom,
           parent_id,
           1 AS niveau,
           nom::text AS chemin
    FROM categorie_niveau
    WHERE parent_id IS NULL

    UNION ALL

    SELECT c.id,
           c.nom,
           c.parent_id,
           a.niveau + 1,
           a.chemin || ' > ' || c.nom
    FROM categorie_niveau AS c
    JOIN arbre AS a ON c.parent_id = a.id
)
SELECT niveau,
       REPEAT('    ', niveau - 1) || nom AS categorie,
       chemin
FROM arbre
ORDER BY chemin;

-- Q11 : Combien de participations et quel score total chaque catégorie racine
--       rassemble-t-elle, sous-catégories comprises ?
-- Fonction : WITH RECURSIVE (total d'une branche)
WITH RECURSIVE branche AS (
    SELECT id,
           id AS racine_id,
           nom AS racine_nom
    FROM categorie_niveau
    WHERE parent_id IS NULL

    UNION ALL

    SELECT c.id,
           b.racine_id,
           b.racine_nom
    FROM categorie_niveau AS c
    JOIN branche AS b ON c.parent_id = b.id
)
SELECT b.racine_nom AS categorie_racine,
       COUNT(DISTINCT b.id) AS nb_categories_dans_la_branche,
       COUNT(e.id) AS nb_participations,
       COALESCE(SUM(e.score), 0) AS score_total
FROM branche AS b
LEFT JOIN partie AS p ON p.categorie_id = b.id
LEFT JOIN jeux AS e ON e.partie_id = p.id
GROUP BY b.racine_id, b.racine_nom
ORDER BY nb_participations DESC;

-- Q12 : Quels sont les jours sans aucun achat entre le 1er juillet et le
--       30 septembre 2026 ?
-- Fonction : generate_series + LEFT JOIN
SELECT jour::date AS jour_sans_achat
FROM generate_series(DATE '2026-07-01', DATE '2026-09-30', INTERVAL '1 day') AS jour
LEFT JOIN achat AS a ON a.date_achat::date = jour::date
WHERE a.id IS NULL
ORDER BY jour;

-- Q13 : Quel est le chiffre d'affaires de chaque skin de personnage, mois par mois ?
-- Fonction : SUM() FILTER (tableau croisé)
SELECT skin_perso,
       SUM(montant) FILTER (WHERE date_trunc('month', date_achat) = DATE '2026-07-01') AS juillet,
       SUM(montant) FILTER (WHERE date_trunc('month', date_achat) = DATE '2026-08-01') AS aout,
       SUM(montant) FILTER (WHERE date_trunc('month', date_achat) = DATE '2026-09-01') AS septembre,
       SUM(montant) AS total
FROM achat
GROUP BY skin_perso
ORDER BY total DESC;

-- Q14 : Combien de participations et quel score moyen par mode de jeu et par rang, avec sous-totaux ?
-- Fonction : GROUP BY ROLLUP + GROUPING()
SELECT CASE WHEN GROUPING(p.mode_de_jeux) = 1 THEN 'TOTAL GENERAL' ELSE p.mode_de_jeux END AS mode_de_jeu,
       CASE WHEN GROUPING(j.rang) = 1 THEN 'Tous rangs' ELSE j.rang END AS rang,
       COUNT(*) AS nb_participations,
       ROUND(AVG(e.score), 0) AS score_moyen
FROM jeux AS e
JOIN joueur AS j ON j.id = e.joueur_id
JOIN partie AS p ON p.id = e.partie_id
GROUP BY ROLLUP (p.mode_de_jeux, j.rang)
ORDER BY GROUPING(p.mode_de_jeux), p.mode_de_jeux, GROUPING(j.rang), j.rang;

-- Q15 : La durée moyenne d'une participation est-elle représentative de la durée médiane ?
-- Fonction : AVG() et percentile_cont(0.5)
SELECT ROUND(AVG(duree_secondes) / 60.0, 1) AS moyenne_minutes,
       ROUND((percentile_cont(0.5) WITHIN GROUP (ORDER BY duree_secondes) / 60.0)::numeric, 1) AS mediane_minutes
FROM jeux;

-- Q16 : Tableau de bord direction : par mois, activité de jeu, chiffre d'affaires et évolution du CA
-- Fonction : CTE + SUM() OVER + LAG()
WITH activite AS (
    SELECT date_trunc('month', date_partie)::date AS mois,
           COUNT(*) AS nb_participations,
           COUNT(DISTINCT joueur_id) AS joueurs_actifs,
           ROUND(AVG(score), 0) AS score_moyen
    FROM jeux
    GROUP BY 1
),
ventes AS (
    SELECT date_trunc('month', date_achat)::date AS mois,
           SUM(montant) AS ca
    FROM achat
    GROUP BY 1
)
SELECT a.mois,
       a.nb_participations,
       a.joueurs_actifs,
       a.score_moyen,
       COALESCE(v.ca, 0) AS ca,
       SUM(COALESCE(v.ca, 0)) OVER (ORDER BY a.mois) AS ca_cumule,
       ROUND(100.0 * (v.ca - LAG(v.ca) OVER (ORDER BY a.mois))
             / NULLIF(LAG(v.ca) OVER (ORDER BY a.mois), 0), 1) AS evolution_ca_pct
FROM activite AS a
LEFT JOIN ventes AS v ON v.mois = a.mois
ORDER BY a.mois;