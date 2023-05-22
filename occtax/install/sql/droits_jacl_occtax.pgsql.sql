SET search_path TO public;

INSERT INTO jacl2_group VALUES ('naturaliz_profil_1', 'naturaliz_profil_1', 0, NULL) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_group VALUES ('naturaliz_profil_2', 'naturaliz_profil_2', 0, NULL) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_group VALUES ('naturaliz_profil_3', 'naturaliz_profil_3', 0, NULL) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_group VALUES ('naturaliz_profil_4', 'naturaliz_profil_4', 0, NULL) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_group VALUES ('naturaliz_profil_5', 'naturaliz_profil_5', 0, NULL) ON CONFLICT DO NOTHING;


INSERT INTO jacl2_subject_group VALUES ('naturaliz.subject.group', 'occtax~jacl2.naturaliz.subject.group.name') ON CONFLICT DO NOTHING;


INSERT INTO jacl2_subject VALUES ('occtax.admin.config.gerer', 'occtax~jacl2.occtax.admin.config.gerer', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('requete.spatiale.maille_01', 'occtax~jacl2.requete.spatiale.maille_01', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('requete.spatiale.maille_02', 'occtax~jacl2.requete.spatiale.maille_02', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('requete.spatiale.cercle', 'occtax~jacl2.requete.spatiale.cercle', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('requete.spatiale.polygone', 'occtax~jacl2.requete.spatiale.polygone', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('requete.spatiale.import', 'occtax~jacl2.requete.spatiale.import', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('requete.spatiale.espace.naturel', 'occtax~jacl2.requete.spatiale.espace.naturel', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('requete.jdd.observation', 'occtax~jacl2.requete.jdd.observation', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('requete.observateur.observation', 'occtax~jacl2.requete.observateur.observation', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('requete.organisme.utilisateur', 'occtax~jacl2.requete.organisme.utilisateur', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('requete.utilisateur.observation', 'occtax~jacl2.requete.utilisateur.observation', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('visualisation.donnees.brutes', 'occtax~jacl2.visualisation.donnees.brutes', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('visualisation.donnees.maille_01', 'occtax~jacl2.visualisation.donnees.maille_01', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('visualisation.donnees.maille_02', 'occtax~jacl2.visualisation.donnees.maille_02', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('visualisation.donnees.sensibles', 'occtax~jacl2.visualisation.donnees.sensibles', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('visualisation.donnees.non.filtrees', 'occtax~jacl2.visualisation.donnees.non.filtrees', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('export.geometries.brutes.selon.diffusion', 'occtax~jacl2.export.geometries.brutes.selon.diffusion', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;
INSERT INTO jacl2_subject VALUES ('visualisation.donnees.brutes.selon.diffusion', 'occtax~jacl2.visualisation.donnees.brutes.selon.diffusion', 'naturaliz.subject.group') ON CONFLICT DO NOTHING;

INSERT INTO jacl2_rights VALUES ('requete.spatiale.maille_01', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('requete.spatiale.maille_02', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('requete.spatiale.cercle', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('requete.spatiale.polygone', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('requete.spatiale.import', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('requete.spatiale.espace.naturel', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('requete.jdd.observation', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('requete.observateur.observation', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('requete.organisme.utilisateur', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('requete.utilisateur.observation', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('visualisation.donnees.brutes', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('visualisation.donnees.maille_01', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('visualisation.donnees.maille_02', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('visualisation.donnees.sensibles', 'naturaliz_profil_1', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('requete.spatiale.maille_02', '__anonymous', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('visualisation.donnees.maille_02', '__anonymous', '-', 0) ON CONFLICT DO NOTHING;
INSERT INTO jacl2_rights VALUES ('visualisation.donnees.non.filtrees', 'admins', '-', 0) ON CONFLICT DO NOTHING;


INSERT INTO jacl2_user_group VALUES ('admin', 'naturaliz_profil_1') ON CONFLICT DO NOTHING;

RESET search_path;
