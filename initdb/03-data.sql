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




from staging.inventaire;