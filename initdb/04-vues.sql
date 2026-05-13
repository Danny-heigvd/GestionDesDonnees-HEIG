-- Vue 1
CREATE VIEW v_lampadaires_detail AS
SELECT
    m.id,
    l.nom                                          AS lieu,
    tm.libelle                                     AS type,
    EXTRACT(YEAR FROM m.date_installation)         AS annee_installation,
    COUNT(i.id)                                    AS nb_pannes,
    SUM(i.cout)                                    AS cout_cumule,
    MAX(i.date)                                    AS derniere_intervention,
    l.latitude,
    l.longitude
FROM mobilier m
JOIN type_mobilier tm ON tm.id = m.id_type_mobilier
JOIN lieu          l  ON l.id  = m.id_lieu
LEFT JOIN intervention i ON i.id_mobilier = m.id
WHERE tm.libelle = 'lampadaire'
GROUP BY m.id, l.nom, tm.libelle, m.date_installation, l.latitude, l.longitude;

-- Vue 2
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
    (nb_pannes * 3)
    + (EXTRACT(YEAR FROM CURRENT_DATE) - annee_installation) * 2
    + (COALESCE(cout_cumule, 0) / 100) AS score_priorite
FROM v_lampadaires_detail
ORDER BY score_priorite DESC;

-- Vue 3
CREATE VIEW v_lampadaires_budget AS
WITH cout_moyen_remplacement AS (
    SELECT AVG(i.cout) AS cout_moyen
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
        lp.latitude,
        lp.longitude,
        cm.cout_moyen,
        SUM(cm.cout_moyen) OVER (ORDER BY lp.score_priorite DESC) AS budget_cumule
    FROM v_lampadaires_priorite lp
    CROSS JOIN cout_moyen_remplacement cm
)
SELECT
    id,
    lieu,
    type,
    score_priorite,
    cout_moyen        AS cout_remplacement_estime,
    budget_cumule,
    latitude,
    longitude
FROM lampadaires_avec_cumul
WHERE budget_cumule <= 50000;