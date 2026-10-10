CREATE TABLE joueur (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(15) NOT NULL UNIQUE,
    skin VARCHAR,
    niveaux INTEGER NOT NULL CHECK (niveaux >= 1),
    rang VARCHAR NOT NULL
);

CREATE TABLE amitie (
    joueur_id INTEGER NOT NULL REFERENCES joueur(id),
    ami_id INTEGER NOT NULL REFERENCES joueur(id),
    PRIMARY KEY (joueur_id, ami_id),
    CHECK (joueur_id <> ami_id)
);

CREATE TABLE categorie_niveau (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    parent_id INTEGER REFERENCES categorie_niveau(id),
    CHECK (parent_id IS NULL OR parent_id <> id),
    UNIQUE (nom, parent_id)
);

CREATE TABLE partie (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    categorie_id INTEGER NOT NULL REFERENCES categorie_niveau(id),
    nb_joueur INTEGER NOT NULL CHECK (nb_joueur > 0),
    mode_de_jeux VARCHAR(30) NOT NULL,
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE jeux (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    joueur_id INTEGER NOT NULL REFERENCES joueur(id),
    partie_id INTEGER NOT NULL REFERENCES partie(id),
    date_partie TIMESTAMP NOT NULL,
    score INTEGER NOT NULL CHECK (score >= 0),
    duree_secondes INTEGER NOT NULL CHECK (duree_secondes > 0),
    UNIQUE (joueur_id, partie_id)
);

CREATE TABLE achat (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    joueur_id INTEGER NOT NULL REFERENCES joueur(id),
    skin_perso VARCHAR(50),
    skin_arme VARCHAR(50),
    montant NUMERIC(8,2) NOT NULL CHECK (montant >= 0),
    date_achat TIMESTAMP NOT NULL
);