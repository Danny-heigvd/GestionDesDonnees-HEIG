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
        WHEN email NOT LIKE '%@%' THEN 'inconnu'
        ELSE TRIM(email)
    END AS email
FROM fournisseurs
;
-- =============================================================================
-- 2. INTERVENTIONS
-- =============================================================================

-- 2.1 Normaliser les dates DD.MM.YYYY → YYYY-MM-DD
SELECT
CASE WHEN date LIKE '%.%.%' THEN TO_DATE(date, 'DD.MM.YYYY')::TEXT
ELSE date
END AS date_normalisee
From intervention;


SELECT
CASE
    WHEN duree = '30 min' THEN 30
    WHEN duree = '1h' THEN 60
    WHEN duree = '1h30' THEN 90
    WHEN duree = '2h' THEN 120
    WHEN duree = '3h' THEN 180
    WHEN duree = 'une matinée' THEN 240
    WHEN duree = 'une journée' THEN 480
    ELSE NULL
END AS duree_minutes;

SELECT
CASE 
    WHEN cout = 'gratuit' THEN 0
    WHEN cout = 'garantie' THEN 0
    WHEN TRIM(cout) = '' THEN NULL
    ELSE cout::NUMERIC
END AS cout_chf
FROM intervention;

SELECT 
SET cout_materiel_chf = cout_materiel::NUMERIC
ELSE NULL
FROM intervention;

-- 2.5 Normaliser la casse de type_intervention
SELECT
SET type_intervention = LOWER(TRIM(type_intervention))
FROM intervention;

-- =============================================================================
-- 3. INVENTAIRE_MOBILIER
-- =============================================================================

SELECT
    CASE
        WHEN id LIKE '%\_%' THEN REPLACE(id, '_', '-')
        ELSE id
    END AS id
FROM inventaire



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

-- 3.3 Normaliser les dates d'installation
 
-- Étape A : DD.MM.YYYY → YYYY-MM-DD
SELECT
    CASE
        WHEN TRIM(date_installation) LIKE '%.%.%'
            THEN TO_DATE(TRIM(date_installation), 'DD.MM.YYYY')
        ELSE date_installation::DATE
    END AS date_installation
FROM inventaire;
 
-- Étape B : année seule → YYYY-01-01
SELECT
    CASE
        WHEN TRIM(date_installation) LIKE '____'
            THEN TRIM(date_installation) || '-01-01'
        ELSE date_installation
    END AS date_installation
FROM inventaire;

--     Étape C : texte français → YYYY-MM-DD (1er du mois par convention)
USELECT
    CASE LOWER(TRIM(date_installation))
        WHEN 'janvier 2019'   THEN '01-01-2019'
        WHEN 'février 2015'   THEN '01-02-2015'
        WHEN 'février 2020'   THEN '01-02-2020'
        WHEN 'février 2021'   THEN '01-02-2021'
        WHEN 'février 2023'   THEN '01-02-2023'
        WHEN 'mars 2014'      THEN '01-03-2014'
        WHEN 'mars 2023'      THEN '01-03-2023'
        WHEN 'avril 2023'     THEN '01-04-2023'
        WHEN 'mai 2017'       THEN '01-05-2017'
        WHEN 'mai 2022'       THEN '01-05-2022'
        WHEN 'mai 2023'       THEN '01-05-2023'
        WHEN 'juin 2022'      THEN '01-06-2022'
        WHEN 'juin 2023'      THEN '01-06-2023'
        WHEN 'juillet 2016'   THEN '01-07-2016'
        WHEN 'juillet 2022'   THEN '01-07-2022'
        WHEN 'octobre 2013'   THEN '01-10-2013'
        WHEN 'octobre 2021'   THEN '01-10-2021'
        WHEN 'novembre 2019'  THEN '01-11-2019'
        WHEN 'novembre 2021'  THEN '01-11-2021'
        WHEN 'décembre 2016'  THEN '01-12-2016'
        WHEN 'décembre 2021'  THEN '01-12-2021'
        WHEN 'décembre 2022'  THEN '01-12-2022'
        ELSE date_installation
    END AS date_installation
FROM inventaire;
-- 3.4 Matériau manquant → 'inconnu'
SELECT
    CASE
        WHEN materiau IS NULL THEN 'inconnu'
        ELSE LOWER(TRIM(materiau))
        END AS matériaux
FROM inventaire;
 
 
-- 3.5 Remarques manquantes → 'aucune'
SELECT
    CASE
        WHEN remarques IS NULL THEN 'aucune'
        ELSE remarques
    END AS remarques
FROM inventaire;

SELECT
    CASE
        WHEN TRIM(date) LIKE '%.%.%' THEN TO_DATE(TRIM(date), 'DD.MM.YYYY')::TEXT
        ELSE TRIM(date)
    END AS date
FROM signalements;