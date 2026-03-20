select * 
FROM fournisseurs
WHERE remarques IS NULL;

-- =============================================================================
-- SCRIPT DE NETTOYAGE BASE DE DONNÉES — PostgreSQL
-- Tables : fournisseurs_contacts, interventions, inventaire_mobilier, signalements
-- =============================================================================
-- RECOMMANDATION : exécuter dans une transaction pour pouvoir rollback si besoin.
-- BEGIN;
--   ... (tout le script) ...
-- COMMIT;  -- ou ROLLBACK; si quelque chose cloche
-- =============================================================================


-- =============================================================================
-- 1. FOURNISSEURS_CONTACTS
-- =============================================================================
-- Problèmes détectés :
--   • Formats de téléphone hétérogènes (+41, 0xx, sans espaces)
--   • Valeur "voir site web" dans la colonne email
--   • Emails manquants (NULL)
-- =============================================================================

-- 1.1 Normaliser les numéros de téléphone au format national CH : 0XX XXX XX XX
UPDATE fournisseurs_contacts
SET telephone = REGEXP_REPLACE(
    REGEXP_REPLACE(
        REGEXP_REPLACE(telephone, '\s+', '', 'g'),  -- supprime tous les espaces
        '^\+41', '0'                                -- +41 → 0
    ),
    '(\d{3})(\d{3})(\d{2})(\d{2})', '\1 \2 \3 \4'  -- reformate en 0XX XXX XX XX
);

-- 1.2 Invalider les emails non conformes (remplace les valeurs parasites par NULL)
UPDATE fournisseurs_contacts
SET email = NULL
WHERE email NOT LIKE '%@%';
-- "voir site web" → NULL

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
-- Problèmes détectés :
--   • Formats de date mixtes (ISO, DD.MM.YYYY)
--   • Durées non standardisées (1h, 1h30, une matinée, une journée…)
--   • Coûts avec suffixes parasites (79.-, CHF 215.-, garantie, gratuit)
--   • Noms de techniciens incohérents (JM, Jean-Marc, Jean-Marc Bonvin…)
--   • Casse incohérente sur type_intervention
-- =============================================================================

-- 2.1 Normaliser les dates au format ISO (YYYY-MM-DD)
--     DD.MM.YYYY → YYYY-MM-DD
UPDATE interventions
SET date = TO_CHAR(
    TO_DATE(date, 'DD.MM.YYYY'),
    'YYYY-MM-DD'
)
WHERE date ~ '^\d{2}\.\d{2}\.\d{4}$';

-- 2.2 Standardiser la durée en minutes (INTEGER) via une nouvelle colonne
--     Les valeurs textuelles sont converties en minutes pour permettre des calculs.
ALTER TABLE interventions ADD COLUMN IF NOT EXISTS duree_minutes INTEGER;

UPDATE interventions SET duree_minutes =
    CASE duree
        WHEN '30 min'       THEN 30
        WHEN '1h'           THEN 60
        WHEN '1h30'         THEN 90
        WHEN '2h'           THEN 120
        WHEN '3h'           THEN 180
        WHEN 'une matinée'  THEN 240   -- convention : demi-journée = 4h
        WHEN 'une journée'  THEN 480   -- convention : journée = 8h
        ELSE NULL
    END;

-- 2.3 Nettoyer la colonne cout_materiel : supprimer "CHF ", ".-", "garantie", "gratuit"
--     et convertir en NUMERIC
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

-- Pour les coûts déjà propres (entiers), recopier directement
UPDATE interventions
SET cout_materiel_chf = cout_materiel::NUMERIC
WHERE cout_materiel::TEXT ~ '^\d+$'
  AND cout_materiel_chf IS NULL;

-- 2.4 Normaliser les noms de techniciens
--     Règle métier : on unifie vers le nom complet quand il est connu
UPDATE interventions SET technicien = 'Jean-Marc Bonvin'
WHERE TRIM(LOWER(technicien)) IN ('jm', 'jean-marc');

UPDATE interventions SET technicien = 'Pedro Alves'
WHERE TRIM(LOWER(technicien)) IN ('pedro', 'p. alves', 'alves pedro');

-- 2.5 Normaliser la casse de type_intervention (tout en minuscules)
UPDATE interventions
SET type_intervention = LOWER(TRIM(type_intervention));

-- 2.6 Valeur par défaut pour les remarques manquantes
UPDATE interventions
SET remarques = 'aucune'
WHERE remarques IS NULL;


-- =============================================================================
-- 3. INVENTAIRE_MOBILIER
-- =============================================================================
-- Problèmes détectés :
--   • IDs avec formats mixtes (B-001, B_3, 1002)
--   • Type avec casse et libellés incohérents (Banc, banc, banc public…)
--   • Dates d'installation : 3 formats + texte en français (février 2021…)
--   • Coordonnées GPS manquantes (3 lignes)
--   • Matériau manquant (5 lignes)
-- =============================================================================

-- 3.1 Normaliser les IDs au format B-XXX (3 chiffres)
--     Les IDs purement numériques (ex: 1002) sont laissés tels quels (à arbitrer)
UPDATE inventaire_mobilier
SET id = REGEXP_REPLACE(id, '[_]', '-', 'g')   -- B_3 → B-3
WHERE id ~ '^[A-Z]_\d+$';

-- Si vous souhaitez zéro-padder (B-3 → B-003) :
-- UPDATE inventaire_mobilier
-- SET id = REGEXP_REPLACE(id, '^([A-Z])-(\d)$', '\1-00\2')
--       WHERE id ~ '^[A-Z]-\d$';
-- UPDATE inventaire_mobilier
-- SET id = REGEXP_REPLACE(id, '^([A-Z])-(\d{2})$', '\1-0\2')
--       WHERE id ~ '^[A-Z]-\d{2}$';

-- 3.2 Normaliser la colonne type (minuscules + libellés unifiés)
UPDATE inventaire_mobilier
SET type = LOWER(TRIM(type));

UPDATE inventaire_mobilier SET type = 'banc'
WHERE type IN ('banc public');

UPDATE inventaire_mobilier SET type = 'lampadaire led'
WHERE type IN ('lampadaire led', 'lampadaire led');  -- casse déjà gérée par LOWER

UPDATE inventaire_mobilier SET type = 'poubelle'
WHERE type IN ('corbeille', 'poubelle tri');

UPDATE inventaire_mobilier SET type = 'fontaine'
WHERE type IN ('fontaine publique');

UPDATE inventaire_mobilier SET type = 'borne ev'
WHERE type IN ('borne recharge ev', 'borne recharge');

UPDATE inventaire_mobilier SET type = 'panneau'
WHERE type IN ('panneau info', 'panneau affichage');

-- 3.3 Normaliser les dates d'installation
--     Étape A : DD.MM.YYYY → YYYY-MM-DD
UPDATE inventaire_mobilier
SET date_installation = TO_CHAR(TO_DATE(date_installation, 'DD.MM.YYYY'), 'YYYY-MM-DD')
WHERE date_installation ~ '^\d{2}\.\d{2}\.\d{4}$';

--     Étape B : années seules (2020) → 2020-01-01 (convention : 1er janvier)
UPDATE inventaire_mobilier
SET date_installation = date_installation || '-01-01'
WHERE date_installation ~ '^\d{4}$';

--     Étape C : texte français → date approximative (1er du mois)
UPDATE inventaire_mobilier SET date_installation = '2021-02-01' WHERE date_installation = 'février 2021';
UPDATE inventaire_mobilier SET date_installation = '2021-12-01' WHERE date_installation = 'décembre 2021';
UPDATE inventaire_mobilier SET date_installation = '2022-06-01' WHERE date_installation = 'juin 2022';
UPDATE inventaire_mobilier SET date_installation = '2022-07-01' WHERE date_installation = 'juillet 2022';
UPDATE inventaire_mobilier SET date_installation = '2023-04-01' WHERE date_installation = 'avril 2023';
UPDATE inventaire_mobilier SET date_installation = '2023-02-01' WHERE date_installation = 'février 2023';
UPDATE inventaire_mobilier SET date_installation = '2023-05-01' WHERE date_installation = 'mai 2023';
UPDATE inventaire_mobilier SET date_installation = '2023-06-01' WHERE date_installation = 'juin 2023';
UPDATE inventaire_mobilier SET date_installation = '2023-03-01' WHERE date_installation = 'mars 2023';
UPDATE inventaire_mobilier SET date_installation = '2022-05-01' WHERE date_installation = 'mai 2022';
UPDATE inventaire_mobilier SET date_installation = '2019-01-01' WHERE date_installation = 'janvier 2019';
UPDATE inventaire_mobilier SET date_installation = '2019-11-01' WHERE date_installation = 'novembre 2019';
UPDATE inventaire_mobilier SET date_installation = '2020-02-01' WHERE date_installation = 'février 2020';
UPDATE inventaire_mobilier SET date_installation = '2021-10-01' WHERE date_installation = 'octobre 2021';
UPDATE inventaire_mobilier SET date_installation = '2021-11-01' WHERE date_installation = 'novembre 2021';
UPDATE inventaire_mobilier SET date_installation = '2016-07-01' WHERE date_installation = 'juillet 2016';
UPDATE inventaire_mobilier SET date_installation = '2016-12-01' WHERE date_installation = 'décembre 2016';
UPDATE inventaire_mobilier SET date_installation = '2017-05-01' WHERE date_installation = 'mai 2017';
UPDATE inventaire_mobilier SET date_installation = '2013-10-01' WHERE date_installation = 'octobre 2013';
UPDATE inventaire_mobilier SET date_installation = '2014-03-01' WHERE date_installation = 'mars 2014';
UPDATE inventaire_mobilier SET date_installation = '2015-02-01' WHERE date_installation = 'février 2015';

-- 3.4 Coordonnées GPS manquantes → NULL (déjà NULL, on s'assure qu'il n'y a pas de chaîne vide)
UPDATE inventaire_mobilier
SET latitude = NULL WHERE TRIM(latitude::TEXT) = '';
UPDATE inventaire_mobilier
SET longitude = NULL WHERE TRIM(longitude::TEXT) = '';

-- 3.5 Matériau manquant → 'inconnu'
UPDATE inventaire_mobilier
SET materiau = 'inconnu'
WHERE materiau IS NULL;

-- 3.6 Remarques manquantes → 'aucune'
UPDATE inventaire_mobilier
SET remarques = 'aucune'
WHERE remarques IS NULL;


-- =============================================================================
-- 4. SIGNALEMENTS
-- =============================================================================
-- Problèmes détectés :
--   • urgence : 129 NULL → valeur par défaut 'normal'
--   • statut : 55 NULL → valeur par défaut 'en attente'
--   • signale_par : 20 NULL → valeur par défaut 'inconnu'
--   • Casse incohérente sur objet et description
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

-- 4.2 Normaliser la casse de la colonne objet (première lettre en majuscule)
--     PostgreSQL n'a pas de INITCAP parfait pour les accents, mais c'est un bon début
UPDATE signalements
SET objet = INITCAP(LOWER(TRIM(objet)));

-- 4.3 Normaliser la casse de description
UPDATE signalements
SET description = INITCAP(LOWER(TRIM(description)));


-- =============================================================================
-- 5. CONTRAINTES POST-NETTOYAGE (optionnel — à adapter à votre schéma)
-- =============================================================================
-- Ces contraintes empêchent la réintroduction de valeurs invalides à l'avenir.

-- 5.1 Valeurs acceptées pour signalements.urgence
ALTER TABLE signalements
    ADD CONSTRAINT chk_urgence
    CHECK (urgence IN ('urgent', 'normal'));

-- 5.2 Valeurs acceptées pour signalements.statut
ALTER TABLE signalements
    ADD CONSTRAINT chk_statut
    CHECK (statut IN ('en attente', 'en cours', 'fait'));

-- 5.3 Valeurs acceptées pour inventaire_mobilier.etat
ALTER TABLE inventaire_mobilier
    ADD CONSTRAINT chk_etat
    CHECK (etat IN ('bon', 'usé', 'à remplacer'));

-- =============================================================================
-- FIN DU SCRIPT
-- =============================================================================
-- Vérifications recommandées après exécution :
--
-- SELECT technicien, COUNT(*) FROM interventions GROUP BY technicien;
-- SELECT type, COUNT(*) FROM inventaire_mobilier GROUP BY type;
-- SELECT urgence, statut, COUNT(*) FROM signalements GROUP BY urgence, statut;
-- SELECT email FROM fournisseurs_contacts WHERE email NOT LIKE '%@%';
-- =============================================================================