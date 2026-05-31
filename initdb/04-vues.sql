CREATE VIEW v_lampadaires_detail AS
SELECT
    m.id,
    l.nom AS lieu,
    ma.libelle AS type,
    EXTRACT(YEAR FROM m.date_installation) AS annee_installation,
    COUNT(DISTINCT i.id) AS nb_pannes,
    COALESCE(SUM(i.cout), 0) AS cout_cumule,
    MAX(i.date) AS derniere_intervention,
    l.latitude,
    l.longitude
FROM mobilier m
LEFT JOIN materiau ma ON ma.id = m.id_materiau
JOIN type_mobilier tm ON tm.id = m.id_type_mobilier
JOIN lieu l ON l.id = m.id_lieu
LEFT JOIN intervention i ON i.id_mobilier = m.id
WHERE tm.libelle = 'lampadaire'
GROUP BY m.id, l.nom, ma.libelle, m.date_installation, l.latitude, l.longitude;

CREATE OR REPLACE VIEW v_lampadaires_priorite AS
SELECT
    id,
    lieu,
    type,
    annee_installation,
    nb_pannes,
    cout_cumule,
    derniere_intervention,
    latitude,
    longitude,
    ROUND(
        (COALESCE(nb_pannes, 0) * 3)
        + (CASE
            WHEN annee_installation IS NULL THEN 30
            ELSE EXTRACT(YEAR FROM CURRENT_DATE) - annee_installation
           END * 2)
        + (COALESCE(cout_cumule, 0) / 100),
        2
    ) AS score_priorite
FROM v_lampadaires_detail
ORDER BY score_priorite DESC;

CREATE VIEW v_lampadaires_budget AS
WITH cout_moyen_remplacement AS (
    SELECT COALESCE(AVG(i.cout), 0) AS cout_moyen
    FROM intervention i
    JOIN type_intervention ti ON ti.id = i.id_type_intervention
    WHERE ti.libelle = 'remplacement complet'
),
lampadaires_avec_cumul AS (
    SELECT
        lp.id,
        lp.lieu,
        lp.type,
        lp.score_priorite,
        ROUND(cm.cout_moyen,2) AS cout_remplacement_estime,

        ROUND(
            SUM(cm.cout_moyen)
            OVER (
                ORDER BY lp.score_priorite DESC, lp.id
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ),
            2
        ) AS budget_cumule,

        lp.latitude,
        lp.longitude
    FROM v_lampadaires_priorite lp
    CROSS JOIN cout_moyen_remplacement cm
)
SELECT *
FROM lampadaires_avec_cumul
WHERE budget_cumule <= 50000
ORDER BY score_priorite DESC;

SELECT * FROM v_lampadaires_detail LIMIT 20;

SELECT * FROM v_lampadaires_priorite LIMIT 20;

SELECT * FROM v_lampadaires_budget;

SELECT *
FROM v_lampadaires_priorite
ORDER BY score_priorite DESC;

SELECT *
FROM v_lampadaires_detail
WHERE nb_pannes > 0;

SELECT AVG(i.cout)
FROM intervention i
JOIN type_intervention ti ON ti.id = i.id_type_intervention
WHERE LOWER(TRIM(ti.libelle)) = 'remplacement complet';

-- Combien de lampadaires au total ?
SELECT COUNT(*) FROM mobilier m
JOIN type_mobilier tm ON tm.id = m.id_type_mobilier
WHERE tm.libelle = 'lampadaire';

-- Combien arrivent dans v_lampadaires_detail ?
SELECT COUNT(*) FROM v_lampadaires_detail;

-- Combien ont un score dans v_lampadaires_priorite ?
SELECT COUNT(*) FROM v_lampadaires_priorite;

SELECT COUNT(*) FROM staging.inventaire
WHERE LOWER(TRIM(type)) LIKE '%lampadaire%';
SELECT DISTINCT type FROM staging.inventaire
WHERE LOWER(TRIM(type)) LIKE '%lampadaire%';
-- Combien de lampadaires du staging n'ont pas de fournisseur associé ?
SELECT COUNT(*)
FROM staging.inventaire inv
LEFT JOIN staging.fournisseur_inventaire fi
    ON REPLACE(fi.id_inventaire, '_', '-') = REPLACE(inv.id, '_', '-')
LEFT JOIN public.fournisseurs fo
    ON fo.entreprise = TRIM(fi.entreprise)
WHERE LOWER(TRIM(inv.type)) LIKE '%lampadaire%'
  AND fo.id IS NULL;

SELECT DISTINCT ma.libelle, m.remarques
FROM mobilier m
JOIN type_mobilier tm ON tm.id = m.id_type_mobilier
JOIN materiau ma ON ma.id = m.id_materiau
WHERE tm.libelle = 'lampadaire'
LIMIT 10;

SELECT id, lieu, score_priorite FROM v_lampadaires_priorite LIMIT 5;
-- Vérifie ce qui manque dans le staging :
SELECT
    COUNT(*) AS total,
    COUNT(date_installation) AS avec_date,
    COUNT(latitude) AS avec_latitude,
    COUNT(longitude) AS avec_longitude
FROM staging.inventaire
WHERE LOWER(TRIM(type)) LIKE '%lampadaire%';
-- Vérifie les interventions liées aux lampadaires :
SELECT COUNT(*) 
FROM intervention i
JOIN mobilier m ON m.id = i.id_mobilier
JOIN type_mobilier tm ON tm.id = m.id_type_mobilier
WHERE tm.libelle = 'lampadaire';
SELECT COUNT(*), COUNT(date_installation)
FROM mobilier m
JOIN type_mobilier tm ON tm.id = m.id_type_mobilier
WHERE tm.libelle = 'lampadaire';

SELECT m.id, m.old_id, COUNT(i.id) AS nb_interventions
FROM mobilier m
JOIN type_mobilier tm ON tm.id = m.id_type_mobilier
LEFT JOIN intervention i ON i.id_mobilier = m.id
WHERE tm.libelle = 'lampadaire'
GROUP BY m.id, m.old_id
ORDER BY nb_interventions DESC
LIMIT 10;
SELECT m.id, m.old_id, COUNT(i.id) AS nb_interventions
FROM mobilier m
JOIN type_mobilier tm ON tm.id = m.id_type_mobilier
LEFT JOIN intervention i ON i.id_mobilier = m.id
WHERE tm.libelle = 'lampadaire'
GROUP BY m.id, m.old_id
ORDER BY nb_interventions DESC
LIMIT 10;
SELECT inv.id, inv.date_installation
FROM staging.inventaire inv
JOIN staging.fournisseur_inventaire fi 
    ON REPLACE(fi.id_inventaire, '_', '-') = REPLACE(inv.id, '_', '-')
WHERE LOWER(TRIM(inv.type)) LIKE '%lampadaire%'
  AND (inv.date_installation IS NULL OR TRIM(inv.date_installation) = '')
LIMIT 10;
SELECT l.nom, l.latitude, l.longitude
FROM mobilier m
JOIN type_mobilier tm ON tm.id = m.id_type_mobilier
JOIN lieu l ON l.id = m.id_lieu
WHERE tm.libelle = 'lampadaire'
  AND l.latitude IS NULL
LIMIT 10;
SELECT inv.id, inv.date_installation
FROM staging.inventaire inv
LEFT JOIN staging.fournisseur_inventaire fi 
    ON REPLACE(fi.id_inventaire, '_', '-') = REPLACE(inv.id, '_', '-')
WHERE LOWER(TRIM(inv.type)) LIKE '%lampadaire%'
  AND fi.id_inventaire IS NULL;

SELECT inv.id, inv.date_installation
FROM staging.inventaire inv
WHERE LOWER(TRIM(inv.type)) LIKE '%lampadaire%'
ORDER BY inv.id;