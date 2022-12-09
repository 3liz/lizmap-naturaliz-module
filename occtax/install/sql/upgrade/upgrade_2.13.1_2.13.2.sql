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
