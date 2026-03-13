-- Créer un schéma dédié pour la staging
CREATE SCHEMA IF NOT EXISTS staging;

-- Table de staging : miroir exact du CSV
-- Tout en TEXT, aucune contrainte
CREATE TABLE staging.inventaire (
  id                TEXT,
  type              TEXT,
  materiau          TEXT,
  lieu              TEXT,
  latitude          TEXT,
  longitude         TEXT,
  date_installation TEXT,
  etat              TEXT,
  remarques         TEXT
);

COPY staging.inventaire_mobilier
FROM '/data/inventaire_mobilier.csv'
WITH (FORMAT csv, HEADER true,
      DELIMITER ',', ENCODING 'UTF8');