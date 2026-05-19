CREATE VIEW v_lampadaires_detail AS
SELECT
    m.id,
    l.nom AS lieu,
    ma.libelle AS type,
    EXTRACT(YEAR FROM m.date_installation) AS annee_installation,
    COUNT(i.id) AS nb_pannes,
    COALESCE(SUM(i.cout), 0) AS cout_cumule,
    MAX(i.date) AS derniere_intervention,
    l.latitude,
    l.longitude
FROM mobilier m
JOIN type_mobilier tm ON tm.id = m.id_type_mobilier
JOIN lieu l ON l.id = m.id_lieu
JOIN materiau ma ON ma.id = m.id_materiau
LEFT JOIN intervention i ON i.id_mobilier = m.id
WHERE tm.libelle = 'lampadaire'
GROUP BY m.id, l.nom, ma.libelle, m.date_installation, l.latitude, l.longitude;

CREATE VIEW v_lampadaires_priorite AS
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
        + (COALESCE(EXTRACT(YEAR FROM CURRENT_DATE) - annee_installation, 0) * 2)
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
        ROUND(cm.cout_moyen, 2) AS cout_remplacement_estime,
        ROUND(
            SUM(cm.cout_moyen) OVER (ORDER BY lp.score_priorite DESC),
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
