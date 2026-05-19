CREATE ROLE citoyen;
CREATE ROLE technicien_role;
CREATE ROLE responsable;

GRANT CONNECT ON DATABASE service_technique TO citoyen;
GRANT CONNECT ON DATABASE service_technique TO technicien_role;
GRANT CONNECT ON DATABASE service_technique TO responsable;

GRANT USAGE ON SCHEMA public TO citoyen;
GRANT USAGE ON SCHEMA public TO technicien_role;
GRANT USAGE ON SCHEMA public TO responsable;

-- Citoyen : peut consulter et créer des signalements uniquement
GRANT SELECT, INSERT ON signalement TO citoyen;
GRANT USAGE, SELECT ON SEQUENCE signalement_id_seq TO citoyen;

-- Technicien : peut consulter, créer et modifier les signalements/interventions
GRANT SELECT, INSERT, UPDATE ON signalement, intervention TO technicien_role;
GRANT SELECT ON mobilier, lieu, type_signalement, source_signalement, type_intervention, technicien TO technicien_role;
GRANT SELECT ON v_lampadaires_detail, v_lampadaires_priorite TO technicien_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO technicien_role;

-- Responsable : accès complet
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO responsable;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO responsable;