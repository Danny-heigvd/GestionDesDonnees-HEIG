-- 1. type_mobilier
INSERT INTO public.type_mobilier(libelle)
SELECT DISTINCT
    CASE
        WHEN type IS NULL OR TRIM(type) = '' THEN 'inconnu'
        ELSE CASE LOWER(TRIM(type))
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
            WHEN 'lampadaire sodium' THEN 'lampadaire'
            ELSE LOWER(TRIM(type))
        END
    END
FROM staging.inventaire;
 
-- 2. materiau
INSERT INTO public.materiau(libelle)
SELECT DISTINCT
    CASE
        WHEN materiau IS NULL OR TRIM(materiau) = '' THEN 'inconnu'
        WHEN LOWER(TRIM(materiau)) = 'metal' THEN 'métal'
        ELSE LOWER(TRIM(materiau))
    END
FROM staging.inventaire;
 
INSERT INTO public.etat(libelle)
SELECT DISTINCT
    CASE
        WHEN etat IS NULL OR TRIM(etat) = '' THEN 'inconnu'
        ELSE LOWER(TRIM(etat))
    END
FROM staging.inventaire;
 
INSERT INTO public.lieu(nom, latitude, longitude)
SELECT DISTINCT
    CASE
        WHEN lieu IS NULL OR TRIM(lieu) = '' THEN 'inconnu'
        ELSE TRIM(lieu)
    END,
    CASE
        WHEN latitude IS NULL OR TRIM(latitude) = '' THEN NULL
        ELSE latitude::DECIMAL(9,6)
    END,
    CASE
        WHEN longitude IS NULL OR TRIM(longitude) = '' THEN NULL
        ELSE longitude::DECIMAL(9,6)
    END
FROM staging.inventaire;
 
-- 5. fournisseurs
-- 5. fournisseurs
INSERT INTO public.fournisseurs(entreprise, contact, telephone, email, remarques)
SELECT DISTINCT ON (entreprise)
    TRIM(entreprise),
    TRIM(contact),
    CASE
        WHEN telephone LIKE '+41%' THEN REPLACE(telephone, '+41 ', '0')
        ELSE TRIM(telephone)
    END,
    CASE
        WHEN email IS NULL OR TRIM(email) = '' THEN 'inconnu'
        WHEN email NOT LIKE '%@%' THEN 'inconnu'
        ELSE TRIM(email)
    END,
    TRIM(remarques)
FROM staging.fournisseurs
WHERE entreprise IS NOT NULL
  AND TRIM(entreprise) <> '';
 
-- 6. mobilier
INSERT INTO public.mobilier(old_id, date_installation, remarques, id_fournisseur, id_type_mobilier, id_lieu, id_etat, id_materiau)
SELECT DISTINCT ON (REPLACE(inv.id, '_', '-'))
    REPLACE(inv.id, '_', '-'),
    CASE
    WHEN inv.date_installation IS NULL OR TRIM(inv.date_installation) = '' THEN NULL
    WHEN TRIM(inv.date_installation) ~ '^\d{2}\.\d{2}\.\d{4}$'
        THEN TO_DATE(TRIM(inv.date_installation), 'DD.MM.YYYY')
    WHEN TRIM(inv.date_installation) ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TO_DATE(TRIM(inv.date_installation), 'YYYY-MM-DD')
    WHEN TRIM(inv.date_installation) ~ '^\d{4}$'
        THEN (TRIM(inv.date_installation) || '-01-01')::DATE
    WHEN TRIM(inv.date_installation) ~ '^[A-Za-zÀ-ÿ]+ \d{4}$'
        THEN (
            '01-' ||
            CASE SPLIT_PART(LOWER(TRIM(inv.date_installation)), ' ', 1)
                WHEN 'janvier'   THEN '01'
                WHEN 'février'   THEN '02'
                WHEN 'mars'      THEN '03'
                WHEN 'avril'     THEN '04'
                WHEN 'mai'       THEN '05'
                WHEN 'juin'      THEN '06'
                WHEN 'juillet'   THEN '07'
                WHEN 'août'      THEN '08'
                WHEN 'septembre' THEN '09'
                WHEN 'octobre'   THEN '10'
                WHEN 'novembre'  THEN '11'
                WHEN 'décembre'  THEN '12'
            END
            || '-' || SPLIT_PART(TRIM(inv.date_installation), ' ', 2)
        )::DATE
    ELSE NULL
END,
    CASE
        WHEN inv.remarques IS NULL OR TRIM(inv.remarques) = '' THEN 'aucune'
        ELSE TRIM(inv.remarques)
    END,
    fo.id,
    tm.id,
    l.id,
    e.id,
    ma.id
FROM staging.inventaire inv
LEFT JOIN staging.fournisseur_inventaire fi
    ON REPLACE(fi.id_inventaire, '_', '-') = REPLACE(inv.id, '_', '-')
LEFT JOIN public.fournisseurs fo
    ON fo.entreprise = TRIM(fi.entreprise)
LEFT JOIN public.type_mobilier tm
    ON tm.libelle = CASE LOWER(TRIM(inv.type))
        WHEN 'banc public' THEN 'banc'
        WHEN 'banc bois' THEN 'banc'
        WHEN 'banc métal' THEN 'banc'
        WHEN 'banc metal' THEN 'banc'
        WHEN 'corbeille' THEN 'poubelle'
        WHEN 'poubelle tri' THEN 'poubelle'
        WHEN 'poubelle recyclage' THEN 'poubelle'
        WHEN 'fontaine publique' THEN 'fontaine'
        WHEN 'fontaine eau' THEN 'fontaine'
        WHEN 'borne recharge ev' THEN 'borne ev'
        WHEN 'borne recharge' THEN 'borne ev'
        WHEN 'borne électrique' THEN 'borne ev'
        WHEN 'panneau info' THEN 'panneau'
        WHEN 'panneau affichage' THEN 'panneau'
        WHEN 'panneau signalisation' THEN 'panneau'
        WHEN 'lampadaire led' THEN 'lampadaire'
        WHEN 'lampadaire public' THEN 'lampadaire'
        WHEN 'lampadaire sodium' THEN 'lampadaire'
        ELSE LOWER(TRIM(inv.type))
    END
LEFT JOIN public.materiau ma
    ON ma.libelle = CASE
        WHEN inv.materiau IS NULL OR TRIM(inv.materiau) = '' THEN 'inconnu'
        WHEN LOWER(TRIM(inv.materiau)) = 'metal' THEN 'métal'
        ELSE LOWER(TRIM(inv.materiau))
    END
LEFT JOIN public.etat e
    ON e.libelle = CASE
        WHEN inv.etat IS NULL OR TRIM(inv.etat) = '' THEN 'inconnu'
        ELSE LOWER(TRIM(inv.etat))
    END
LEFT JOIN public.lieu l
    ON l.nom = CASE
        WHEN inv.lieu IS NULL OR TRIM(inv.lieu) = '' THEN 'inconnu'
        ELSE TRIM(inv.lieu)
    END
WHERE fo.id IS NOT NULL
  AND tm.id IS NOT NULL
  AND l.id IS NOT NULL
  AND e.id IS NOT NULL
  AND ma.id IS NOT NULL;
 
INSERT INTO public.source_signalement(nom)
SELECT DISTINCT
    CASE
        WHEN signale_par IS NULL OR TRIM(signale_par) = '' THEN 'inconnu'
        ELSE LOWER(TRIM(signale_par))
    END
FROM staging.signalements;
 
INSERT INTO public.type_signalement(urgence, statut)
SELECT DISTINCT
    CASE
        WHEN urgence IS NULL OR TRIM(urgence) = '' THEN 'inconnu'
        ELSE LOWER(TRIM(urgence))
    END,
    CASE
        WHEN statut IS NULL OR TRIM(statut) = '' THEN 'inconnu'
        ELSE LOWER(TRIM(statut))
    END
FROM staging.signalements;
 
-- 9. signalement
INSERT INTO public.signalement(date, objet, description, id_mobilier, id_type_signalement, id_source_signalement)
SELECT DISTINCT ON (st.date, st.objet, st.description)
    CASE
    WHEN st.date IS NULL OR TRIM(st.date) = '' THEN NULL
    WHEN TRIM(st.date) ~ '^\d{2}\.\d{2}\.\d{4}$'
        THEN TO_DATE(TRIM(st.date), 'DD.MM.YYYY')
    WHEN TRIM(st.date) ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TO_DATE(TRIM(st.date), 'YYYY-MM-DD')
    WHEN TRIM(st.date) ~ '^\d{4}$'
        THEN (TRIM(st.date) || '-01-01')::DATE
    WHEN TRIM(st.date) ~ '^[A-Za-zÀ-ÿ]+ \d{4}$'
        THEN (
            '01-' ||
            CASE SPLIT_PART(LOWER(TRIM(st.date)), ' ', 1)
                WHEN 'janvier'   THEN '01'
                WHEN 'février'   THEN '02'
                WHEN 'mars'      THEN '03'
                WHEN 'avril'     THEN '04'
                WHEN 'mai'       THEN '05'
                WHEN 'juin'      THEN '06'
                WHEN 'juillet'   THEN '07'
                WHEN 'août'      THEN '08'
                WHEN 'septembre' THEN '09'
                WHEN 'octobre'   THEN '10'
                WHEN 'novembre'  THEN '11'
                WHEN 'décembre'  THEN '12'
            END
            || '-' || SPLIT_PART(TRIM(st.date), ' ', 2)
        )::DATE
    ELSE NULL
END,
    TRIM(st.objet),
    TRIM(st.description),
    m.id,
    ts.id,
    ss.id
FROM staging.signalements st
LEFT JOIN public.type_signalement ts
    ON ts.urgence = CASE
        WHEN st.urgence IS NULL OR TRIM(st.urgence) = '' THEN 'inconnu'
        ELSE LOWER(TRIM(st.urgence))
    END
    AND ts.statut = CASE
        WHEN st.statut IS NULL OR TRIM(st.statut) = '' THEN 'inconnu'
        ELSE LOWER(TRIM(st.statut))
    END
LEFT JOIN public.source_signalement ss
    ON ss.nom = CASE
        WHEN st.signale_par IS NULL OR TRIM(st.signale_par) = '' THEN 'inconnu'
        ELSE LOWER(TRIM(st.signale_par))
    END
LEFT JOIN public.type_mobilier tm
    ON tm.libelle = CASE
        WHEN LOWER(st.objet) LIKE '%lampadaire%' THEN 'lampadaire'
        WHEN LOWER(st.objet) LIKE '%banc%' THEN 'banc'
        WHEN LOWER(st.objet) LIKE '%poubelle%' THEN 'poubelle'
        WHEN LOWER(st.objet) LIKE '%corbeille%' THEN 'poubelle'
        WHEN LOWER(st.objet) LIKE '%fontaine%' THEN 'fontaine'
        WHEN LOWER(st.objet) LIKE '%borne%' THEN 'borne ev'
        WHEN LOWER(st.objet) LIKE '%panneau%' THEN 'panneau'
        ELSE NULL
    END
LEFT JOIN public.mobilier m
    ON m.id_type_mobilier = tm.id
    AND EXISTS (
        SELECT 1
        FROM public.lieu l
        WHERE l.id = m.id_lieu
          AND LOWER(st.objet) LIKE '%' || LOWER(l.nom) || '%'
    )
WHERE ts.id IS NOT NULL
  AND ss.id IS NOT NULL
  AND m.id IS NOT NULL
  AND st.date IS NOT NULL
  AND TRIM(st.date) <> ''
ORDER BY st.date, st.objet, st.description, m.id;
 
-- 10. type_intervention
INSERT INTO public.type_intervention(libelle)
SELECT DISTINCT
    CASE
        WHEN type_intervention IS NULL OR TRIM(type_intervention) = '' THEN 'inconnu'
        ELSE LOWER(TRIM(type_intervention))
    END
FROM staging.interventions;
 
INSERT INTO public.technicien(nom)
SELECT DISTINCT
    CASE
        WHEN technicien IS NULL OR TRIM(technicien) = '' THEN 'inconnu'
        ELSE TRIM(technicien)
    END
FROM staging.interventions;
-- 13. intervention
INSERT INTO public.intervention(date, duree, cout, remarque, id_signalement, id_type_intervention, id_technicien, id_mobilier)
SELECT DISTINCT ON (i.date, i.objet, i.type_intervention, i.technicien, i.duree, i.cout_materiel)
    CASE
    WHEN i.date IS NULL OR TRIM(i.date) = '' THEN NULL
    WHEN TRIM(i.date) ~ '^\d{2}\.\d{2}\.\d{4}$'
        THEN TO_DATE(TRIM(i.date), 'DD.MM.YYYY')
    WHEN TRIM(i.date) ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TO_DATE(TRIM(i.date), 'YYYY-MM-DD')
WHEN TRIM(i.date) ~ '^\d{4}$'
    THEN (TRIM(i.date) || '-01-01')::DATE
WHEN TRIM(i.date) ~ '^[A-Za-zÀ-ÿ]+ \d{4}$'
        THEN (
            '01-' ||
            CASE SPLIT_PART(LOWER(TRIM(i.date)), ' ', 1)
                WHEN 'janvier'   THEN '01'
                WHEN 'février'   THEN '02'
                WHEN 'mars'      THEN '03'
                WHEN 'avril'     THEN '04'
                WHEN 'mai'       THEN '05'
                WHEN 'juin'      THEN '06'
                WHEN 'juillet'   THEN '07'
                WHEN 'août'      THEN '08'
                WHEN 'septembre' THEN '09'
                WHEN 'octobre'   THEN '10'
                WHEN 'novembre'  THEN '11'
                WHEN 'décembre'  THEN '12'
            END
            || '-' || SPLIT_PART(TRIM(i.date), ' ', 2)
        )::DATE
    ELSE NULL
END,
    CASE
        WHEN i.duree = '30 min' THEN 30
        WHEN i.duree = '1h' THEN 60
        WHEN i.duree = '1h30' THEN 90
        WHEN i.duree = '2h' THEN 120
        WHEN i.duree = '3h' THEN 180
        WHEN i.duree = 'une matinée' THEN 240
        WHEN i.duree = 'une journée' THEN 480
        ELSE NULL
    END,
    CASE
        WHEN i.cout_materiel = 'gratuit' THEN 0
        WHEN i.cout_materiel = 'garantie' THEN 0
        WHEN i.cout_materiel IS NULL OR TRIM(i.cout_materiel) = '' THEN NULL
        ELSE REPLACE(REPLACE(i.cout_materiel, '.-', ''), 'CHF ', '')::DECIMAL(10,2)
    END,
    TRIM(i.remarques),
    s.id,
    ti.id,
    t.id,
    s.id_mobilier
FROM staging.interventions i
LEFT JOIN public.signalement s
    ON s.objet = i.objet
LEFT JOIN public.type_intervention ti
    ON ti.libelle = CASE
        WHEN i.type_intervention IS NULL OR TRIM(i.type_intervention) = '' THEN 'inconnu'
        ELSE LOWER(TRIM(i.type_intervention))
    END
LEFT JOIN public.technicien t
    ON t.nom = CASE
        WHEN i.technicien IS NULL OR TRIM(i.technicien) = '' THEN 'inconnu'
        ELSE TRIM(i.technicien)
    END
WHERE ti.id IS NOT NULL
  AND t.id IS NOT NULL
  AND s.id IS NOT NULL
  AND s.id_mobilier IS NOT NULL
  AND i.date IS NOT NULL
  AND TRIM(i.date) <> ''
ORDER BY i.date, i.objet, i.type_intervention, i.technicien, i.duree, i.cout_materiel, s.id;
 
INSERT INTO public.mobilier_signalement(id_mobilier, id_signalement, libelle)
SELECT
    id_mobilier,
    id,
    description
FROM public.signalement
WHERE id_mobilier IS NOT NULL
ORDER BY id_mobilier, id;
