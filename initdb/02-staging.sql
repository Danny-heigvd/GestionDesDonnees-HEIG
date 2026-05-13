02 : 
 
 
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
 
COPY staging.inventaire
FROM '/data/inventaire_mobilier.csv'
WITH (FORMAT csv, HEADER true,
      DELIMITER ';', ENCODING 'UTF8');
 
CREATE TABLE staging.fournisseurs (
  entreprise                TEXT,
  contact                   TEXT,
  telephone                 TEXT,
  email                     TEXT,
  type_materiel             TEXT,
  remarques                 TEXT
 
);
 
COPY staging.fournisseurs
FROM '/data/fournisseurs_contacts.csv'
WITH (FORMAT csv, HEADER true,
      DELIMITER ';', ENCODING 'UTF8');    
 
CREATE TABLE staging.interventions (
  date                TEXT,
  objet               TEXT,
  type_intervention   TEXT,
  technicien          TEXT,
  duree               TEXT,
  cout_materiel       TEXT,
  remarques           TEXT
);
 
COPY staging.interventions
FROM '/data/interventions.csv'
WITH (FORMAT csv, HEADER true,
      DELIMITER ';', ENCODING 'UTF8');
 
CREATE TABLE staging.signalements (
  date                  TEXT,
  signale_par           TEXT,
  objet                 TEXT,
  description           TEXT,
  urgence               TEXT,
  statut                TEXT
);
 
COPY staging.signalements
FROM '/data/signalements.csv'
WITH (FORMAT csv, HEADER true,
      DELIMITER ';', ENCODING 'UTF8');        
 
 
CREATE TABLE staging.fournisseur_inventaire (
    id_inventaire TEXT,
    type          TEXT,
    materiau      TEXT,
    entreprise    TEXT
);
 
COPY staging.fournisseur_inventaire
FROM '/data/fournisseur_inventaire.csv'
WITH (FORMAT csv, HEADER true,
      DELIMITER ';', ENCODING 'UTF8');      
 
