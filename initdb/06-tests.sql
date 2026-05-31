-- ============================================================
-- 06-tests.sql
-- Vérification complète du brief C
-- Plan de remplacement des lampadaires
-- ============================================================


-- ============================================================
-- TEST 1 — Intégrité des données de base
-- ============================================================

-- 1.1 Comptage général des tables
SELECT 'mobilier'     AS table_name, COUNT(*) AS nb_lignes FROM mobilier
UNION ALL
SELECT 'signalement',                COUNT(*) FROM signalement
UNION ALL
SELECT 'intervention',               COUNT(*) FROM intervention
UNION ALL
SELECT 'lieu',                       COUNT(*) FROM lieu
UNION ALL
SELECT 'fournisseurs',               COUNT(*) FROM fournisseurs
UNION ALL
SELECT 'type_mobilier',              COUNT(*) FROM type_mobilier
UNION ALL
SELECT 'type_intervention',          COUNT(*) FROM type_intervention
UNION ALL
SELECT 'technicien',                 COUNT(*) FROM technicien;

-- 1.2 Aucune intervention orpheline (sans signalement)
SELECT COUNT(*) AS interventions_orphelines
FROM intervention
WHERE id_signalement IS NULL;
-- Attendu : 0

-- 1.3 Aucun signalement orphelin (sans mobilier)
SELECT COUNT(*) AS signalements_orphelins
FROM signalement
WHERE id_mobilier IS NULL;
-- Attendu : 0

-- 1.4 Aucun mobilier sans lieu
SELECT COUNT(*) AS mobilier_sans_lieu
FROM mobilier
WHERE id_lieu IS NULL;
-- Attendu : 0


-- ============================================================
-- TEST 2 — Livrable 1 : v_lampadaires_detail
-- ============================================================

-- 2.1 La vue existe et retourne 35 lampadaires
SELECT COUNT(*) AS nb_lampadaires
FROM v_lampadaires_detail;
-- Attendu : 35

-- 2.2 Toutes les colonnes requises par le brief sont présentes
SELECT
    id,
    lieu,
    type,
    annee_installation,
    nb_pannes,
    cout_cumule,
    derniere_intervention,
    latitude,
    longitude
FROM v_lampadaires_detail
LIMIT 5;

-- 2.3 Aucun lampadaire avec un type autre que sodium ou led
SELECT DISTINCT type FROM v_lampadaires_detail;
-- Attendu : seulement 'led' et 'sodium'

-- 2.4 Les coûts cumulés sont positifs ou nuls
SELECT COUNT(*) AS couts_negatifs
FROM v_lampadaires_detail
WHERE cout_cumule < 0;
-- Attendu : 0

-- 2.5 Lampadaires avec le plus de pannes (top 5)
SELECT id, lieu, type, nb_pannes, cout_cumule
FROM v_lampadaires_detail
ORDER BY nb_pannes DESC
LIMIT 5;


-- ============================================================
-- TEST 3 — Livrable 2 : v_lampadaires_priorite
-- ============================================================

-- 3.1 La vue retourne 35 lampadaires
SELECT COUNT(*) AS nb_lampadaires
FROM v_lampadaires_priorite;
-- Attendu : 35

-- 3.2 Le score est bien décroissant
SELECT id, lieu, score_priorite,
    CASE
        WHEN score_priorite > LAG(score_priorite) OVER (ORDER BY score_priorite DESC)
        THEN '❌ ERREUR ordre'
        ELSE '✅ OK'
    END AS ordre_correct
FROM v_lampadaires_priorite;
-- Attendu : toutes les lignes à ✅ OK

-- 3.3 Aucun score négatif
SELECT COUNT(*) AS scores_negatifs
FROM v_lampadaires_priorite
WHERE score_priorite < 0;
-- Attendu : 0

-- 3.4 Le lampadaire en tête a le score le plus élevé
SELECT id, lieu, score_priorite
FROM v_lampadaires_priorite
ORDER BY score_priorite DESC
LIMIT 3;
-- Attendu : id 31 en premier, puis 24


-- ============================================================
-- TEST 4 — Livrable 3 : v_lampadaires_budget
-- ============================================================

-- 4.1 La vue retourne 35 lampadaires (tous dans le budget)
SELECT COUNT(*) AS nb_lampadaires_selectionnes
FROM v_lampadaires_budget;
-- Attendu : 35

-- 4.2 Le budget cumulé ne dépasse pas 50 000 CHF
SELECT MAX(budget_cumule) AS budget_total_utilise
FROM v_lampadaires_budget;
-- Attendu : 5139.62 (largement sous 50 000)

-- 4.3 Le budget est bien cumulatif et croissant
SELECT id, lieu, cout_remplacement_estime, budget_cumule,
    CASE
        WHEN budget_cumule < LAG(budget_cumule) OVER (ORDER BY score_priorite DESC)
        THEN '❌ ERREUR cumul'
        ELSE '✅ OK'
    END AS cumul_correct
FROM v_lampadaires_budget;
-- Attendu : toutes les lignes à ✅ OK

-- 4.4 Le coût moyen de remplacement est cohérent
SELECT ROUND(AVG(cout), 2) AS cout_moyen_remplacement
FROM intervention i
JOIN type_intervention ti ON ti.id = i.id_type_intervention
WHERE LOWER(TRIM(ti.libelle)) = 'remplacement complet';
-- Attendu : 146.85

-- 4.5 Les coordonnées GPS sont présentes (sauf Centre sportif)
SELECT id, lieu, latitude, longitude
FROM v_lampadaires_budget
WHERE latitude IS NULL OR longitude IS NULL;
-- Attendu : seulement Centre sportif (id 51)


-- ============================================================
-- TEST 5 — Cohérence globale
-- ============================================================

-- 5.1 Tous les lampadaires de v_detail sont dans v_priorite
SELECT COUNT(*) AS manquants_dans_priorite
FROM v_lampadaires_detail d
WHERE d.id NOT IN (SELECT id FROM v_lampadaires_priorite);
-- Attendu : 0

-- 5.2 Tous les lampadaires de v_priorite sont dans v_budget
SELECT COUNT(*) AS manquants_dans_budget
FROM v_lampadaires_priorite p
WHERE p.id NOT IN (SELECT id FROM v_lampadaires_budget);
-- Attendu : 0

-- 5.3 Le nombre de pannes dans v_detail correspond aux interventions réelles
SELECT
    m.id,
    COUNT(i.id) AS nb_interventions_reelles,
    vd.nb_pannes AS nb_pannes_vue,
    CASE
        WHEN COUNT(i.id) = vd.nb_pannes THEN '✅ OK'
        ELSE '❌ ERREUR'
    END AS coherence
FROM mobilier m
JOIN type_mobilier tm ON tm.id = m.id_type_mobilier
LEFT JOIN intervention i ON i.id_mobilier = m.id
JOIN v_lampadaires_detail vd ON vd.id = m.id
WHERE tm.libelle = 'lampadaire'
GROUP BY m.id, vd.nb_pannes
ORDER BY coherence DESC;
-- Attendu : toutes les lignes à ✅ OK