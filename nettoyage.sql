-- téléphone normalisé (version simple)
SELECT 
    CASE
        WHEN telephone LIKE '+41%' THEN '0' 
        ELSE
            TRIM(telephone)
    END AS telephone
FROM staging.fournisseurs;
    -- email
SELECT 
    CASE
        WHEN email IS NULL OR TRIM(email) = '' THEN 'inconnu'
        ELSE TRIM(email)
    END AS email
from fournisseurs


-- 1.3 Valeur par défaut pour les emails manquants
UPDATE fournisseurs_contacts
SET email = 'inconnu'
WHERE email IS NULL;

-- 1.4 Valeur par défaut pour les contacts manquants
UPDATE fournisseurs_contacts
SET contact = 'inconnu'
WHERE contact IS NULL;

-- =============================================================================
-- 2. INTERVENTIONS
-- =============================================================================

-- 2.1 Normaliser les dates DD.MM.YYYY → YYYY-MM-DD
UPDATE interventions
SET date = CASE
    WHEN date LIKE '%.%.%' THEN TO_DATE(date, 'DD.MM.YYYY')::TEXT
END;

UPDATE interventions SET duree_minutes =
    CASE duree
        WHEN '30 min'       THEN 30
        WHEN '1h'           THEN 60
        WHEN '1h30'         THEN 90
        WHEN '2h'           THEN 120
        WHEN '3h'           THEN 180
        WHEN 'une matinée'  THEN 240
        WHEN 'une journée'  THEN 480
        ELSE NULL
    END;

UPDATE interventions
SET cout_materiel_chf =
    CASE
        WHEN LOWER(TRIM(cout_materiel)) IN ('gratuit', 'garantie') THEN 0
        WHEN TRIM(cout_materiel) = '' THEN NULL
        ELSE cout_materiel::NUMERIC
    END;

UPDATE interventions
SET cout_materiel_chf = cout_materiel::NUMERIC
WHERE cout_materiel_chf IS NULL
  AND TRIM(cout_materiel) <> '';

-- 2.5 Normaliser la casse de type_intervention
UPDATE interventions
SET type_intervention = LOWER(TRIM(type_intervention));

-- 2.6 Valeur par défaut pour les remarques manquantes
UPDATE interventions
SET remarques = 'aucune'
WHERE remarques IS NULL;

-- =============================================================================
-- 3. INVENTAIRE_MOBILIER
-- =============================================================================

UPDATE inventaire_mobilier
SET id = REPLACE(id, '_', '-')
WHERE id LIKE '%\_%';



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




from staging.inventaire;


-UPDATE inventaire_mobilier
SET type =
    CASE LOWER(TRIM(type))

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

    END;

-- 3.3 Normaliser les dates d'installation

--     Étape A : DD.MM.YYYY → YYYY-MM-DD
UPDATE inventaire_mobilier
SET date_installation =
    CASE
        WHEN TRIM(date_installation) LIKE '%.%.%' 
            THEN TO_DATE(TRIM(date_installation), 'DD.MM.YYYY')
        ELSE date_installation::DATE
    END;

--     Étape B : année seule → YYYY-01-01
UPDATE inventaire_mobilier
SET date_installation =
    CASE
        WHEN TRIM(date_installation) LIKE '____'
            THEN TRIM(date_installation) || '-01-01'
        ELSE date_installation
    END;

--     Étape C : texte français → YYYY-MM-DD (1er du mois par convention)
UPDATE inventaire_mobilier
SET date_installation =
    CASE LOWER(TRIM(date_installation))

        WHEN 'janvier 2019'   THEN '2019-01-01'
        WHEN 'février 2015'   THEN '2015-02-01'
        WHEN 'février 2020'   THEN '2020-02-01'
        WHEN 'février 2021'   THEN '2021-02-01'
        WHEN 'février 2023'   THEN '2023-02-01'
        WHEN 'mars 2014'      THEN '2014-03-01'
        WHEN 'mars 2023'      THEN '2023-03-01'
        WHEN 'avril 2023'     THEN '2023-04-01'
        WHEN 'mai 2017'       THEN '2017-05-01'
        WHEN 'mai 2022'       THEN '2022-05-01'
        WHEN 'mai 2023'       THEN '2023-05-01'
        WHEN 'juin 2022'      THEN '2022-06-01'
        WHEN 'juin 2023'      THEN '2023-06-01'
        WHEN 'juillet 2016'   THEN '2016-07-01'
        WHEN 'juillet 2022'   THEN '2022-07-01'
        WHEN 'octobre 2013'   THEN '2013-10-01'
        WHEN 'octobre 2021'   THEN '2021-10-01'
        WHEN 'novembre 2019'  THEN '2019-11-01'
        WHEN 'novembre 2021'  THEN '2021-11-01'
        WHEN 'décembre 2016'  THEN '2016-12-01'
        WHEN 'décembre 2021'  THEN '2021-12-01'
        WHEN 'décembre 2022'  THEN '2022-12-01'

        ELSE date_installation
    END;

-- 3.4 Matériau manquant → 'inconnu'
UPDATE inventaire_mobilier
SET materiau = 'inconnu'
WHERE materiau IS NULL;

-- 3.5 Remarques manquantes → 'aucune'
UPDATE inventaire_mobilier
SET remarques = 'aucune'
WHERE remarques IS NULL;