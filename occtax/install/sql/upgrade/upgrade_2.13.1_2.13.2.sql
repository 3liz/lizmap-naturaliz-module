DROP TABLE IF EXISTS taxon.medias;
CREATE TABLE IF NOT EXISTS taxon.medias (
    id serial PRIMARY KEY NOT NULL,
    cd_nom bigint NOT NULL,
    cd_ref bigint NOT NULL,
    principal boolean DEFAULT False,
    source text NOT NULL DEFAULT 'inpn',
    id_origine integer,
    url_origine text,
    media_path text,
    titre text,
    auteur text,
    description text,
    licence text
)
;

ALTER TABLE taxon.medias ADD CONSTRAINT taxon_media_unique UNIQUE (cd_ref, source, id_origine, media_path);

COMMENT ON TABLE taxon.medias
IS 'Stockage des informations sur les médias liés aux taxons. Plusieurs sources possibles: inpn ou local.
Le chemin enregistré dans media_path est le chemin relatif vers le fichier par rapport au répertoire Lizmap.';

COMMENT ON COLUMN taxon.medias.id IS 'Identifiant automatique';
COMMENT ON COLUMN taxon.medias.cd_nom IS 'CD_NOM du taxon';
COMMENT ON COLUMN taxon.medias.cd_ref IS 'CD_REF du taxon';
COMMENT ON COLUMN taxon.medias.principal IS 'Si la photographie est la photographie principale, mettre True (pas encore supporté)';
COMMENT ON COLUMN taxon.medias.source IS 'Source de la photographie: mettre local si la photographie est ajoutée manuellement, ou inpn si elle provient de l''API de l''INPN';
COMMENT ON COLUMN taxon.medias.id_origine IS 'Identifiant d''origine du media dans l''API de l''INPN';
COMMENT ON COLUMN taxon.medias.url_origine IS 'URL d''origine du média téléchargé depuis l''API de l''INPN';
COMMENT ON COLUMN taxon.medias.media_path IS 'Chemin relatif du fichier image par rapport au projet QGIS de l''aplication Naturaliz';
COMMENT ON COLUMN taxon.medias.titre IS 'Titre de la photographie';
COMMENT ON COLUMN taxon.medias.auteur IS 'Auteur (copyright) de la photographie';
COMMENT ON COLUMN taxon.medias.description IS 'Description';
COMMENT ON COLUMN taxon.medias.licence IS 'Licence. Par exemple: CC-BY-SA';
