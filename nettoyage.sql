-- =============================================================================
-- SCRIPT DE NETTOYAGE BASE DE DONNÉES — PostgreSQL
-- Tables : fournisseurs_contacts, interventions, inventaire_mobilier, signalements
-- =============================================================================
-- Exécuter dans une transaction pour pouvoir annuler si besoin :
--
--   BEGIN;
--     \i nettoyage_bd_final.sql
--   COMMIT;   ← valider
--   -- ou ROLLBACK; pour tout annuler
--
-- =============================================================================


-- =============================================================================
-- 1. FOURNISSEURS_CONTACTS
-- =============================================================================

-- 1.1 Normaliser les téléphones au format 0XX XXX XX XX
--     Étape A : supprimer les espaces et remplacer +41 par 0
UPDATE fournisseurs_contacts
SET telephone = REGEXP_REPLACE(
    REGEXP_REPLACE(TRIM(telephone), '\s+', '', 'g'),
    '^\+41', '0'
);

--     Étape B : reformater les 10 chiffres en 0XX XXX XX XX
UPDATE fournisseurs_contacts
SET telephone = REGEXP_REPLACE(
    telephone,
    '^(\d{3})(\d{3})(\d{2})(\d{2})$',
    '\1 \2 \3 \4'
)
WHERE telephone ~ '^\d{10}$';

-- 1.2 Invalider les emails non conformes (ex: "voir site web") → NULL
UPDATE fournisseurs_contacts
SET email = NULL
WHERE email NOT LIKE '%@%';

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
SET date = TO_CHAR(
    TO_DATE(date, 'DD.MM.YYYY'),
    'YYYY-MM-DD'
)
WHERE date ~ '^\d{2}\.\d{2}\.\d{4}$';

-- 2.2 Ajouter une colonne duree_minutes et la remplir
ALTER TABLE interventions ADD COLUMN IF NOT EXISTS duree_minutes INTEGER;

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

-- 2.3 Ajouter une colonne cout_materiel_chf et la remplir
ALTER TABLE interventions ADD COLUMN IF NOT EXISTS cout_materiel_chf NUMERIC(10,2);

UPDATE interventions
SET cout_materiel_chf =
    CASE
        WHEN LOWER(cout_materiel::TEXT) IN ('garantie', 'gratuit') THEN 0
        ELSE REGEXP_REPLACE(
                REGEXP_REPLACE(cout_materiel::TEXT, 'CHF\s*', '', 'gi'),
                '\.-$', '', 'g'
             )::NUMERIC
    END
WHERE cout_materiel IS NOT NULL;

UPDATE interventions
SET cout_materiel_chf = cout_materiel::NUMERIC
WHERE cout_materiel::TEXT ~ '^\d+$'
  AND cout_materiel_chf IS NULL;

-- 2.4 Unifier les noms de techniciens
UPDATE interventions SET technicien = 'Jean-Marc Bonvin'
WHERE TRIM(LOWER(technicien)) IN ('jm', 'jean-marc');

UPDATE interventions SET technicien = 'Pedro Alves'
WHERE TRIM(LOWER(technicien)) IN ('pedro', 'p. alves', 'alves pedro');

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

-- 3.1 Normaliser les IDs : B_3 → B-3
UPDATE inventaire_mobilier
SET id = REGEXP_REPLACE(id, '_', '-', 'g')
WHERE id ~ '^[A-Z]_\d+$';

-- 3.2 Normaliser la colonne type en minuscules puis unifier les libellés
UPDATE inventaire_mobilier
SET type = LOWER(TRIM(type));

UPDATE inventaire_mobilier SET type = 'banc'
WHERE type = 'banc public';

UPDATE inventaire_mobilier SET type = 'poubelle'
WHERE type IN ('corbeille', 'poubelle tri');

UPDATE inventaire_mobilier SET type = 'fontaine'
WHERE type = 'fontaine publique';

UPDATE inventaire_mobilier SET type = 'borne ev'
WHERE type IN ('borne recharge ev', 'borne recharge');

UPDATE inventaire_mobilier SET type = 'panneau'
WHERE type IN ('panneau info', 'panneau affichage');

-- 3.3 Normaliser les dates d'installation

--     Étape A : DD.MM.YYYY → YYYY-MM-DD
UPDATE inventaire_mobilier
SET date_installation = TO_CHAR(
    TO_DATE(TRIM(date_installation), 'DD.MM.YYYY'),
    'YYYY-MM-DD'
)
WHERE TRIM(date_installation) ~ '^\d{2}\.\d{2}\.\d{4}$';

--     Étape B : année seule → YYYY-01-01
UPDATE inventaire_mobilier
SET date_installation = TRIM(date_installation) || '-01-01'
WHERE TRIM(date_installation) ~ '^\d{4}$';

--     Étape C : texte français → YYYY-MM-DD (1er du mois par convention)
UPDATE inventaire_mobilier
SET date_installation = CASE LOWER(TRIM(date_installation))
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
END
WHERE TRIM(date_installation) ~ '^[a-zA-ZÀ-ÿ]+ \d{4}$';

-- 3.4 Matériau manquant → 'inconnu'
UPDATE inventaire_mobilier
SET materiau = 'inconnu'
WHERE materiau IS NULL;

-- 3.5 Remarques manquantes → 'aucune'
UPDATE inventaire_mobilier
SET remarques = 'aucune'
WHERE remarques IS NULL;


-- =============================================================================
-- 4. SIGNALEMENTS
-- =============================================================================

-- 4.1 Valeurs par défaut pour les champs manquants
UPDATE signalements
SET urgence = 'normal'
WHERE urgence IS NULL;

UPDATE signalements
SET statut = 'en attente'
WHERE statut IS NULL;

UPDATE signalements
SET signale_par = 'inconnu'
WHERE signale_par IS NULL;

-- 4.2 Normaliser la casse de objet et description
UPDATE signalements
SET objet = INITCAP(LOWER(TRIM(objet)));

UPDATE signalements
SET description = INITCAP(LOWER(TRIM(description)));


-- =============================================================================
-- 5. CONTRAINTES POST-NETTOYAGE
-- =============================================================================

ALTER TABLE signalements
    ADD CONSTRAINT chk_urgence
    CHECK (urgence IN ('urgent', 'normal'));

ALTER TABLE signalements
    ADD CONSTRAINT chk_statut
    CHECK (statut IN ('en attente', 'en cours', 'fait'));

ALTER TABLE inventaire_mobilier
    ADD CONSTRAINT chk_etat
    CHECK (etat IN ('bon', 'usé', 'à remplacer'));


-- =============================================================================
-- VÉRIFICATIONS RECOMMANDÉES APRÈS EXÉCUTION
-- =============================================================================
-- SELECT telephone FROM fournisseurs_contacts;
-- SELECT technicien, COUNT(*) FROM interventions GROUP BY 1;
-- SELECT DISTINCT date_installation FROM inventaire_mobilier WHERE date_installation !~ '^\d{4}-\d{2}-\d{2}$';
-- SELECT urgence, statut, COUNT(*) FROM signalements GROUP BY 1, 2;
-- =============================================================================