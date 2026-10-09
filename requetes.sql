
-- Nombre de lignes par table
SELECT 'joueur' AS table_nom, COUNT(*) FROM joueur
UNION ALL
SELECT 'categorie_niveau', COUNT(*) FROM categorie_niveau
UNION ALL
SELECT 'partie', COUNT(*) FROM partie
UNION ALL
SELECT 'jeux', COUNT(*) FROM jeux
UNION ALL
SELECT 'achat', COUNT(*) FROM achat;

-- Vérification de la période des événements
SELECT
    COUNT(*) AS nombre_evenements,
    MIN(date_partie) AS premiere_date,
    MAX(date_partie) AS derniere_date
FROM jeux;

-- Vérification des catégories et sous-catégories
SELECT
    enfant.nom AS sous_categorie,
    parent.nom AS categorie_parente
FROM categorie_niveau AS enfant
         LEFT JOIN categorie_niveau AS parent
                   ON enfant.parent_id = parent.id
ORDER BY parent.id, enfant.id;

-- Vérification des clés étrangères
SELECT
    j.nom,
    p.mode_de_jeux,
    e.score,
    e.duree_secondes,
    e.date_partie
FROM jeux AS e
         JOIN joueur AS j ON j.id = e.joueur_id
         JOIN partie AS p ON p.id = e.partie_id
ORDER BY e.date_partie
    LIMIT 20;