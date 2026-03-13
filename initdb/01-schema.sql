CREATE TABLE fournisseurs (
    id_fournisseur INT AUTO_INCREMENT PRIMARY KEY,
    entreprise VARCHAR(150) NOT NULL,
    contact VARCHAR(150),
    telephone VARCHAR(30),
    email VARCHAR(150),
    remarques TEXT
);
 
CREATE TABLE type_mobilier (
    id_type_mobilier INT AUTO_INCREMENT PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);
 
CREATE TABLE materiau (
    id_materiau INT AUTO_INCREMENT PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);
 
CREATE TABLE etat (
    id_etat INT AUTO_INCREMENT PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);
 
CREATE TABLE lieu (
    id_lieu INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(150) NOT NULL,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6)
);
 
CREATE TABLE source_signalement (
    id_source_signalement INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL
);
 
CREATE TABLE type_signalement (
    id_type_signalement INT AUTO_INCREMENT PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);
 
CREATE TABLE type_intervention (
    id_type_intervention INT AUTO_INCREMENT PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);
 
CREATE TABLE technicien_contrat (
    id_technicien_contrat INT AUTO_INCREMENT PRIMARY KEY,
    date_debut DATE NOT NULL,
    date_fin DATE
);
 
CREATE TABLE mobilier (
    id_mobilier INT AUTO_INCREMENT PRIMARY KEY,
    date_installation DATE,
    remarque TEXT,
    fk_fournisseur INT NOT NULL,
    fk_type_mobilier INT NOT NULL,
    fk_lieu INT NOT NULL,
    fk_etat INT NOT NULL,
    fk_materiau INT NOT NULL,
    FOREIGN KEY (fk_fournisseur) REFERENCES fournisseurs(id_fournisseur),
    FOREIGN KEY (fk_type_mobilier) REFERENCES type_mobilier(id_type_mobilier),
    FOREIGN KEY (fk_lieu) REFERENCES lieu(id_lieu),
    FOREIGN KEY (fk_etat) REFERENCES etat(id_etat),
    FOREIGN KEY (fk_materiau) REFERENCES materiau(id_materiau)
);
 
CREATE TABLE signalement (
    id_signalement INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    objet VARCHAR(200),
    description TEXT,
    fk_type_signalement INT NOT NULL,
    fk_source_signalement INT NOT NULL,
    FOREIGN KEY (fk_type_signalement) REFERENCES type_signalement(id_type_signalement),
    FOREIGN KEY (fk_source_signalement) REFERENCES source_signalement(id_source_signalement)
);
 
CREATE TABLE mobilier_signalement (
    fk_mobilier INT NOT NULL,
    fk_signalement INT NOT NULL,
    PRIMARY KEY (fk_mobilier, fk_signalement),
    FOREIGN KEY (fk_mobilier) REFERENCES mobilier(id_mobilier),
    FOREIGN KEY (fk_signalement) REFERENCES signalement(id_signalement)
);
 
CREATE TABLE technicien (
    id_technicien INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(150) NOT NULL,
    technicien_contrat VARCHAR(100),
    fk_technicien_contrat INT NOT NULL,
    FOREIGN KEY (fk_technicien_contrat) REFERENCES technicien_contrat(id_technicien_contrat)
);
 
CREATE TABLE intervention (
    id_intervention INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    duree INT,
    cout DECIMAL(10,2),
    remarque TEXT,
    fk_signalement INT NOT NULL,
    fk_type_intervention INT NOT NULL,
    fk_technicien INT NOT NULL,
    FOREIGN KEY (fk_signalement) REFERENCES signalement(id_signalement),
    FOREIGN KEY (fk_type_intervention) REFERENCES type_intervention(id_type_intervention),
    FOREIGN KEY (fk_technicien) REFERENCES technicien(id_technicien)
);