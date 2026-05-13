-- Active: 1773414820841@@127.0.0.1@5438@service_technique
-- 1. type_mobilier
INSERT INTO public.type_mobilier(libelle)
SELECT DISTINCT (CASE LOWER(TRIM(type))
        WHEN 'banc' THEN 'banc'
        WHEN 'banc public' THEN 'banc'
        WHEN 'banc bois' THEN 'banc'
        WHEN 'banc métal' THEN 'banc'
        WHEN 'banc metal' THEN 'banc'
        WHEN 'poubelle' THEN 'poubelle'
        WHEN 'corbeille' THEN 'poubelle'
        WHEN 'poubelle tri' THEN 'poubelle'
        WHEN 'poubelle recyclage' THEN 'poubelle'
        WHEN 'fontaine' THEN 'fontaine'
        WHEN 'fontaine publique' THEN 'fontaine'
        WHEN 'fontaine eau' THEN 'fontaine'
        WHEN 'borne ev' THEN 'borne ev'
        WHEN 'borne recharge ev' THEN 'borne ev'
        WHEN 'borne recharge' THEN 'borne ev'
        WHEN 'borne électrique' THEN 'borne ev'
        WHEN 'panneau' THEN 'panneau'
        WHEN 'panneau info' THEN 'panneau'
        WHEN 'panneau affichage' THEN 'panneau'
        WHEN 'panneau signalisation' THEN 'panneau'
        WHEN 'lampadaire' THEN 'lampadaire'
        WHEN 'lampadaire led' THEN 'lampadaire'
        WHEN 'lampadaire public' THEN 'lampadaire'
        ELSE LOWER(TRIM(type))
        END) AS type_normalise
FROM staging.inventaire;
 
-- 2. materiau
INSERT INTO public.materiau(libelle)
SELECT
    CASE
        WHEN materiau IS NULL THEN 'inconnu'
        ELSE LOWER(TRIM(materiau))
    END
FROM staging.inventaire;
 
INSERT INTO public.etat(libelle)
SELECT
    CASE
        WHEN etat IS NULL THEN 'inconnu'
        ELSE LOWER(TRIM(etat))
    END
FROM staging.inventaire;
 
INSERT INTO public.lieu(nom, latitude, longitude)
SELECT
    CASE
        WHEN lieu IS NULL THEN 'inconnu'
        ELSE TRIM(lieu)
    END,
    CASE
        WHEN latitude IS NULL THEN NULL
        ELSE latitude::DECIMAL(9,6)
    END,
    CASE
        WHEN longitude IS NULL THEN NULL
        ELSE longitude::DECIMAL(9,6)
    END
FROM staging.inventaire;
 
-- 5. fournisseurs
INSERT INTO public.fournisseurs(entreprise, telephone, email)
SELECT
    entreprise,
    CASE
        WHEN telephone LIKE '+41%' THEN REPLACE(telephone, '+41 ', '0')
        ELSE TRIM(telephone)
    END AS telephone,
    CASE
        WHEN email IS NULL OR TRIM(email) = '' THEN 'inconnu'
        WHEN email NOT LIKE '%@%' THEN 'inconnu'
        ELSE TRIM(email)
    END AS email
FROM staging.fournisseurs;
 
-- 6. mobilier
INSERT INTO public.mobilier(id, date_installation, remarques, id_fournisseur, id_type_mobilier, id_lieu, id_etat, id_materiau)



SELECT
    CASE
        WHEN id LIKE '%\_%' THEN REPLACE(id, '_', '-')
        ELSE id
    END,
    CASE
        WHEN TRIM(date_installation) LIKE '%.%.%'
            THEN TO_DATE(TRIM(date_installation), 'DD.MM.YYYY')
        WHEN TRIM(date_installation) LIKE '____'
            THEN (TRIM(date_installation) || '-01-01')::DATE
        ELSE NULL
    END,
    CASE
        WHEN remarques IS NULL THEN 'aucune'
        ELSE remarques
    END,
    fo.id AS id_fournisseur,
    tm.id AS id_type_mobilier,
    l.id AS id_lieu,
    e.id AS id_etat,
    m.id AS id_materiau

    LEFT JOIN staging.fournisseur_inventaire fi ON fi.id_inventaire = inv.id
    LEFT JOIN public.fournisseurs fo ON fo.entreprise = fi.entreprise
    LEFT JOIN public.type_mobilier tm ON tm.libelle = i.type
    LEFT JOIN public.materiau m ON m.libelle = i.materiau
    LEFT JOIN public.etat e ON e.libelle = i.etat
    LEFT JOIN public.lieu l ON l.nom = i.lieu
FROM staging.inventaire;
 
INSERT INTO public.source_signalement(nom)
SELECT
    CASE
        WHEN source IS NULL THEN 'inconnu'
        ELSE LOWER(TRIM(source))
    END
FROM staging.signalements;
 
 INSERT INTO public.type_signalement(libelle)
SELECT
    CASE
        WHEN type_signalement IS NULL THEN 'inconnu'
        ELSE LOWER(TRIM(type_signalement))
    END
FROM staging.signalements;
 
-- 9. signalement
INSERT INTO public.signalement(date)
SELECT
    CASE
        WHEN TRIM(date) LIKE '%.%.%'
            THEN TO_DATE(TRIM(date), 'DD.MM.YYYY')
        ELSE TRIM(date)::DATE
    END
    LEFT JOIN public.type_signalement ts ON ts.libelle = st.objet
    LEFT JOIN public.source_signalement ss ON ss.nom = st.signale_par,
FROM staging.signalements;
 
-- 10. type_intervention
INSERT INTO public.type_intervention(libelle)
SELECT
    LOWER(TRIM(type_intervention))
FROM staging.interventions;
 
INSERT INTO public.technicien(nom, id_technicien_contrat)
SELECT
    CASE
        WHEN nom IS NULL THEN 'inconnu'
        ELSE TRIM(nom)
    END,
FROM staging.techniciens;
-- 13. intervention
INSERT INTO public.intervention(date, duree, cout_materiel)
SELECT
    CASE
        WHEN date LIKE '%.%.%'
            THEN TO_DATE(date, 'DD.MM.YYYY')
        ELSE date::DATE
    END,
    CASE
        WHEN duree = '30 min' THEN 30
        WHEN duree = '1h' THEN 60
        WHEN duree = '1h30' THEN 90
        WHEN duree = '2h' THEN 120
        WHEN duree = '3h' THEN 180
        WHEN duree = 'une matinée' THEN 240
        WHEN duree = 'une journée' THEN 480
        ELSE NULL
    END,
    CASE
        WHEN cout_materiel = 'gratuit' THEN 0
        WHEN cout_materiel = 'garantie' THEN 0
        WHEN TRIM(cout_materiel) = '' THEN NULL
        ELSE cout_materiel::NUMERIC
    END AS cout_chf,
    LEFT JOIN public.type_intervention ti ON ti.libelle = i.type_intervention,
FROM staging.interventions;
 
INSERT INTO public.mobilier_signalement(id_mobilier, id_signalement, libelle)
SELECT
    CASE
        WHEN st.objet IS NULL OR TRIM(st.objet) = '' THEN 'inconnu'
        ELSE TRIM(st.objet)
    END,
    LEFT JOIN public.signalement s ON s.objet = st.objet,
    LEFT JOIN public.mobilier m ON m.id_type_mobilier = tm.id,
FROM staging.signalements;