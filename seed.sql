--20 joueur
INSERT INTO joueur (nom, amis, skin, niveaux, rank)
SELECT
    'joueur_' || g,
    'ami_' || g,
    (ARRAY['Ninja', 'Robot', 'Dragon', 'Fantome'])
    [1 + (g % 4)],
    1 + (g % 100),
    (ARRAY['Bronze', 'Argent', 'Or', 'Diamant'])
        [1 + (g % 4)]
FROM generate_series(1, 20) AS g;

-- 3 catégories parentes
INSERT INTO categorie_niveau (nom, parent_id)
VALUES
    ('Debutant', NULL),
    ('Intermediaire', NULL),
    ('Expert', NULL);

-- 12 sous-catégories
INSERT INTO categorie_niveau (nom, parent_id)
SELECT
    'Sous_niveau_' || g,
    1 + ((g - 1) % 3)
FROM generate_series(1, 12) AS g;

--20 parties
INSERT INTO partie (
    categorie_id, nb_joueur, mode_de_jeux, created_at
)
SELECT
    1 + (g % 15),
    2 + (g % 9),
    (ARRAY['Solo', 'Duo', 'Equipe'])
    [1 + (g % 3)],
    TIMESTAMP '2026-07-01 10:00:00'
        + g * INTERVAL '1 day'
FROM generate_series(1, 20) AS g;

--150 événements dans jeux

SELECT setseed(0.42);

INSERT INTO jeux (
    joueur_id, partie_id, date_partie, score, duree_secondes
)
SELECT
    1 + ((g - 1) / 20),
    1 + ((g - 1) % 20),
    TIMESTAMP '2026-07-01 00:00:00'
    + floor((g - 1) * 92.0 / 150) * INTERVAL '1 day'
    + (g % 20) * INTERVAL '14 minutes',
    floor(random() * 5001)::INTEGER,
    60 + floor(random() * 3541)::INTEGER
FROM generate_series(1, 150) AS s(g);

--30 achat

INSERT INTO achat (
    joueur_id,
    skin_perso,
    skin_arme,
    montant,
    date_achat
)
SELECT
    1 + ((g - 1) % 20),
    (ARRAY['Ninja', 'Dragon', 'Robot', 'Fantome'])
    [1 + (g % 4)],
    (ARRAY['Laser', 'Epee', 'Arc', 'Marteau'])
    [1 + (g % 4)],
    (5 + (g % 46))::NUMERIC(8,2),
    TIMESTAMP '2026-07-01 12:00:00'
    + g * INTERVAL '2 days'
FROM generate_series(1, 30) AS g;