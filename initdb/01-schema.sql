CREATE TABLE fournisseurs (
    id SERIAL PRIMARY KEY,
    entreprise VARCHAR(150),
    contact VARCHAR(150),
    telephone VARCHAR(30),
    email VARCHAR(150),
    remarques VARCHAR(150)
);

CREATE TABLE mobilier (
    id SERIAL PRIMARY KEY,
    date_installation DATE,
    remarque VARCHAR(150),
   id_fournisseur INTEGER NOT NULL REFERENCES fournisseurs(id),
    id_type_mobilier INTEGER NOT NULL REFERENCES type_mobilier(id),
    id_lieu INTEGER NOT NULL REFERENCES lieu(id),
    id_etat INTEGER NOT NULL REFERENCES etat(id),
    id_materiau INTEGER NOT NULL REFERENCES materiau(id)
);
 
CREATE TABLE type_mobilier (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);
 
CREATE TABLE materiau (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);
 
CREATE TABLE etat (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);
 
CREATE TABLE lieu (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(150) NOT NULL,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6)
);

CREATE TABLE signalement (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    objet VARCHAR(200),
    description VARCHAR(200),
    id_type_signalement INTEGER NOT NULL REFERENCES type_signalement(id),
    id_source_signalement INTEGER NOT NULL REFERENCES source_signalement(id)
);

CREATE TABLE mobilier_signalement (
    id SERIAL PRIMARY KEY,
      id_mobilier INTEGER NOT NULL REFERENCES mobilier(id),
    id_signalement INTEGER NOT NULL REFERENCES signalement(id),
);

CREATE TABLE source_signalement (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL
);
 
CREATE TABLE type_signalement (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);

CREATE TABLE intervention (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    duree INT,
    cout DECIMAL(10,2),
    remarque VARCHAR(200),
    id_signalement INTEGER NOT NULL REFERENCES signalement(id),
    id_type_intervention INTEGER NOT NULL REFERENCES type_intervention(id),
    id_technicien INTEGER NOT NULL REFERENCES technicien(id),
    id_mobilier INTEGER NOT NULL REFERENCES mobilier(id)
);
 
CREATE TABLE type_intervention (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);

CREATE TABLE technicien (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(150) NOT NULL,
    id_technicien_contrat INTEGER NOT NULL REFERENCES technicien_contrat(id)
);
 
CREATE TABLE technicien_contrat (
    id SERIAL PRIMARY KEY,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL
);
 