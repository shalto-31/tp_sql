-- =========================================================
-- requetes.sql : requêtes de vérification et requêtes analytiques
-- Base : jeu en ligne (joueur, partie, jeux, achat, categorie_niveau)
-- Charger d'abord schema.sql puis seed.sql.
-- =========================================================


-- =========================================================
-- 0. VÉRIFICATIONS (palier 1)
-- =========================================================

-- Nombre de lignes par table
SELECT 'joueur' AS table_nom, COUNT(*) FROM joueur
UNION ALL SELECT 'amitie', COUNT(*) FROM amitie
UNION ALL SELECT 'categorie_niveau', COUNT(*) FROM categorie_niveau
UNION ALL SELECT 'partie', COUNT(*) FROM partie
UNION ALL SELECT 'jeux', COUNT(*) FROM jeux
UNION ALL SELECT 'achat', COUNT(*) FROM achat;

-- Période couverte par la table d'événements (doit faire au moins 3 mois)
SELECT COUNT(*) AS nombre_evenements,
       MIN(date_partie) AS premiere_date,
       MAX(date_partie) AS derniere_date
FROM jeux;

-- Table hiérarchique : chaque catégorie avec son parent
SELECT enfant.nom AS categorie, parent.nom AS categorie_parente
FROM categorie_niveau AS enfant
LEFT JOIN categorie_niveau AS parent ON enfant.parent_id = parent.id
ORDER BY parent.id NULLS FIRST, enfant.id;


-- =========================================================
-- PALIER 2 : FONCTIONS DE FENÊTRE
-- =========================================================

-- ---------------------------------------------------------
-- Q1 : Dans chaque rang (Bronze, Argent, Or, Diamant), comment se classent
--      les joueurs selon leur score total ?
-- Fonction : RANK() avec PARTITION BY
-- Principe : on additionne les scores par joueur (GROUP BY), puis RANK()
--            numérote les joueurs séparément dans chaque rang. Deux joueurs
--            à égalité reçoivent la même place, et la place suivante est sautée.
-- ---------------------------------------------------------
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


-- ---------------------------------------------------------
-- Q2 : Quels sont les 3 meilleurs joueurs (score moyen par partie) dans
--      chaque mode de jeu (Solo, Duo, Equipe) ?
-- Fonction : ROW_NUMBER() avec PARTITION BY, dans une CTE
-- Principe : une CTE calcule le score moyen par joueur et par mode ; une
--            deuxième numérote les joueurs dans chaque mode ; le SELECT final
--            garde les 3 premiers. Le filtre ne peut pas être mis dans la
--            requête qui contient la fonction de fenêtre, d'où la CTE.
-- ---------------------------------------------------------
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


-- ---------------------------------------------------------
-- Q3 : Quel est le chiffre d'affaires cumulé des achats, mois après mois ?
-- Fonction : SUM() OVER (ORDER BY ...)
-- Principe : on calcule d'abord le CA de chaque mois, puis SUM() OVER
--            (ORDER BY mois) additionne le mois courant et tous les précédents.
-- ---------------------------------------------------------
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


-- ---------------------------------------------------------
-- Q4 : De combien (en %) le chiffre d'affaires évolue-t-il d'une semaine
--      à l'autre ?
-- Fonction : LAG()
-- Principe : LAG(ca) va chercher le CA de la ligne précédente (la semaine
--            d'avant). L'évolution vaut (ca - ca_précédent) / ca_précédent.
--            NULLIF évite une division par zéro. La première semaine n'a pas
--            de précédente : son évolution est NULL.
-- ---------------------------------------------------------
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


-- ---------------------------------------------------------
-- Q5 : Quelle part du chiffre d'affaires total chaque skin de personnage
--      représente-t-il ?
-- Fonction : SUM(...) OVER () (fenêtre sur toutes les lignes)
-- Principe : après le GROUP BY, chaque ligne contient le CA d'un skin.
--            SUM(SUM(montant)) OVER () additionne ces CA pour obtenir le total
--            général, sans supprimer les lignes comme le ferait un GROUP BY.
-- ---------------------------------------------------------
SELECT skin_perso,
       SUM(montant) AS ca,
       ROUND(100.0 * SUM(montant) / SUM(SUM(montant)) OVER (), 1) AS part_du_ca_pct
FROM achat
GROUP BY skin_perso
ORDER BY ca DESC;


-- ---------------------------------------------------------
-- Q6 : Comment le score moyen évolue-t-il au fil des jours, en lissant les
--      variations avec une moyenne mobile ?
-- Fonction : AVG() OVER (ORDER BY ... ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
-- Principe : on calcule le score moyen de chaque jour où il y a eu des parties.
--            Le cadre explicite prend la ligne courante et les 6 précédentes,
--            soit 7 jours d'activité (les jours sans partie n'ont pas de ligne).
--            Les 6 premières lignes sont calculées sur moins de 7 valeurs.
-- ---------------------------------------------------------
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


-- ---------------------------------------------------------
-- Q7 : Quels joueurs jouent bien au-dessus ou en dessous de la moyenne de
--      leur rang ?
-- Fonction : AVG() OVER (PARTITION BY ...)
-- Principe : on calcule le score moyen de chaque joueur, puis la moyenne de
--            ces scores dans son rang. L'écart est la différence entre les deux.
--            Un écart positif signifie que le joueur fait mieux que son rang.
-- ---------------------------------------------------------
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