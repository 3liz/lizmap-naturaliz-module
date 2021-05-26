DROP TABLE IF EXISTS occtax.validation_panier;
CREATE TABLE occtax.validation_panier (
    id serial NOT NULL PRIMARY KEY,
    usr_login character varying NOT NULL,
    identifiant_permanent text NOT NULL
);

ALTER TABLE occtax.validation_panier ADD CONSTRAINT validation_panier_usr_login_identifiant_permanent_key UNIQUE (usr_login, identifiant_permanent);
