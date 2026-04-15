iNSERT INTO public.type_mobilier(libelle)
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

INSERT INTO public.materiau(libelle)
SELECT
    CASE
        WHEN materiau IS NULL THEN 'inconnu'
        ELSE LOWER(TRIM(materiau))
    END
FROM staging.inventaire;

INSERT INTO public.fournisseurs(entreprise,telephone,email)
SELECT 
entreprise,
    CASE
        WHEN telephone LIKE '+41%' THEN REPLACE(telephone, '+41 ', '0')
        ELSE
            TRIM(telephone)
    END AS telephone,
    CASE
        WHEN email IS NULL OR TRIM(email) = '' THEN 'inconnu'
        WHEN email NOT LIKE '%@%' THEN 'inconnu'
        ELSE TRIM(email)
    END AS email
FROM staging.fournisseurs;

INSERT INTO public.signalement(date)
SELECT
    CASE
        WHEN TRIM(date) LIKE '%.%.%' 
            THEN TO_DATE(TRIM(date), 'DD.MM.YYYY')
        ELSE TRIM(date)::DATE
    END
FROM staging.signalements;

INSERT INTO public.type_intervention(libelle)
SELECT 
    LOWER(TRIM(type_intervention))
FROM staging.interventions;

INSERT INTO public.mobilier(id,date_installation,remarques)
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
    END
FROM staging.inventaire;

INSERT INTO public.intervention(date,duree,cout_materiel)
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
    END AS cout_chf
FROM staging.interventions;




Ce qu'il faut faire pour la prochaine fois !!! - transpser les tables, c'est a dire faire insert into la table mobilier par exemple et mettre select type from inventaire pour que la table mobilierde 1 existe et de 2 quelle est du contenu
il faut faire ca pour toutes les colonnes dont on a rien netoyer mais que donc les tables "finale", donc nos tables qu'on a créé, existe, ont du contenu et soit utilisable
