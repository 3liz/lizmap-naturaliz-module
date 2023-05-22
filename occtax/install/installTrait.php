<?php


trait installTrait
{
    protected function setupOcctaxDatabase($db, $sqlPath)
    {

        // Get SRID
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $this->getParameter('srid');
        if(empty($srid)){
            $srid = $ini->getValue('srid', 'naturaliz');
        }

        // Add occtax schema and tables
        $sqlPath = $sqlPath.'install.pgsql.sql';
        $sqlTpl = jFile::read( $sqlPath );
        $tpl = new jTpl();
        $tpl->assign('SRID', $srid);
        $sql = $tpl->fetchFromString($sqlTpl, 'text');
        $db->exec($sql);

        // Add gestion
        $sqlPath = $sqlPath.'gestion.pgsql.sql';
        $sqlTpl = jFile::read( $sqlPath );
        $tpl = new jTpl();
        $tpl->assign('SRID', $srid);
        $sql = $tpl->fetchFromString($sqlTpl, 'text');
        $sql.= jFile::read( $sqlPath.'gestion.data.pgsql.sql' );
        $db->exec($sql);

        // try to add a foreign key for gestion.demande / jlx_user
        try {
            $defaultProfile = jProfiles::get('jdb', 'default');
            $lizmap_schema = 'public';
            if (array_key_exists('search_path', $defaultProfile)) {
                $search_path = $defaultProfile['search_path'];
                $explode = explode(',', $search_path);
                foreach ($explode as $item) {
                    if (strpos(trim($item), 'lizmap_') === 0){
                        $lizmap_schema = trim($item);
                    };
                }
            }
            $sql = '
                    ALTER TABLE gestion.demande ADD CONSTRAINT demande_user_login_fk
                    FOREIGN KEY (usr_login) REFERENCES '.$lizmap_schema.'.jlx_user (usr_login)
                    ON DELETE RESTRICT;
                    ';
            $db->exec($sql);
        } catch (Exception $e){
            jLog::log("Naturaliz gestion - Cannot add foreign key demande_user_login_fk");
            jLog::log($e->getMessage());
        }

        // Add extension validation
        // DO NOT USE TEMPLATE : no need (no srid) AND bug with some PostgreSQL regexp inside
        $sqlPath = $sqlPath.'extension_validation.pgsql.sql';
        $sql = jFile::read( $sqlPath );
        $db->exec($sql);

        // Add materialized views
        $sqlPath = $sqlPath.'materialized_views.pgsql.sql';
        $sqlTpl = jFile::read( $sqlPath );
        $tpl = new jTpl();
        $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
        $tpl->assign('colonne_locale', $colonne_locale);
        $sql = $tpl->fetchFromString($sqlTpl, 'text');
        $db->exec($sql);

        // Import
        $sqlPath = $sqlPath.'import.pgsql.sql';
        $sqlTpl = jFile::read( $sqlPath );
        $tpl = new jTpl();
        $tpl->assign('SRID', $srid);
        $sql = $tpl->fetchFromString($sqlTpl, 'text');
        $db->exec($sql);

    }

    protected function setupOcctaxRights()
    {

        // Create subjects
        jAcl2DbManager::addSubjectGroup ('naturaliz.subject.group', 'occtax~jacl2.naturaliz.subject.group.name');
        jAcl2DbManager::addSubject( 'occtax.admin.config.gerer', 'occtax~jacl2.occtax.admin.config.gerer', 'naturaliz.subject.group');

        jAcl2DbManager::addSubject( 'requete.spatiale.maille_01', 'occtax~jacl2.requete.spatiale.maille_01', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'requete.spatiale.maille_02', 'occtax~jacl2.requete.spatiale.maille_02', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'requete.spatiale.cercle', 'occtax~jacl2.requete.spatiale.cercle', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'requete.spatiale.polygone', 'occtax~jacl2.requete.spatiale.polygone', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'requete.spatiale.import', 'occtax~jacl2.requete.spatiale.import', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'requete.spatiale.espace.naturel', 'occtax~jacl2.requete.spatiale.espace.naturel', 'naturaliz.subject.group');

        jAcl2DbManager::addSubject( 'requete.jdd.observation', 'occtax~jacl2.requete.jdd.observation', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'requete.observateur.observation', 'occtax~jacl2.requete.observateur.observation', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'requete.organisme.utilisateur', 'occtax~jacl2.requete.organisme.utilisateur', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'requete.utilisateur.observation', 'occtax~jacl2.requete.utilisateur.observation', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'visualisation.donnees.brutes', 'occtax~jacl2.visualisation.donnees.brutes', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'visualisation.donnees.brutes.selon.diffusion', 'occtax~jacl2.visualisation.donnees.brutes.selon.diffusion', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'visualisation.donnees.maille_01', 'occtax~jacl2.visualisation.donnees.maille_01', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'visualisation.donnees.maille_02', 'occtax~jacl2.visualisation.donnees.maille_02', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'visualisation.donnees.sensibles', 'occtax~jacl2.visualisation.donnees.sensibles', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'visualisation.donnees.non.filtrees', 'occtax~jacl2.visualisation.donnees.non.filtrees', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject( 'export.geometries.brutes.selon.diffusion', 'occtax~jacl2.export.geometries.brutes.selon.diffusion', 'naturaliz.subject.group');

        // create some users in jAuth
        require_once(JELIX_LIB_PATH.'auth/jAuth.class.php');
        require_once(JELIX_LIB_PATH.'plugins/auth/db/db.auth.php');

        // Create Jacl2 group
        for( $i=1; $i<=5; $i++ ) {
            jAcl2DbUserGroup::createGroup(
                'naturaliz_profil_'.$i,
                'naturaliz_profil_'.$i
            );
        }

        // Set rights on groups
        jAcl2DbManager::setRightsOnGroup(
            'naturaliz_profil_1',
            array(
                'occtax.admin.config.gerer'=>false,
                'requete.spatiale.maille_01'=>true,
                'requete.spatiale.maille_02'=>true,
                'requete.spatiale.cercle'=>true,
                'requete.spatiale.polygone'=>true,
                'requete.spatiale.import'=>true,
                'requete.spatiale.espace.naturel'=>true,
                'requete.jdd.observation'=>true,
                'requete.observateur.observation'=>true,
                'requete.organisme.utilisateur'=>true,
                'requete.utilisateur.observation'=>true,
                'visualisation.donnees.brutes'=>true,
                'visualisation.donnees.maille_01'=>true,
                'visualisation.donnees.maille_02'=>true,
                'visualisation.donnees.sensibles'=>true,
            )
        );

        jAcl2DbManager::setRightsOnGroup(
            'naturaliz_profil_2',
            array(
                'requete.spatiale.maille_01'=>true,
                'requete.spatiale.maille_02'=>true,
                'requete.spatiale.cercle'=>true,
                'requete.spatiale.polygone'=>true,
                'requete.spatiale.import'=>true,
                'requete.spatiale.espace.naturel'=>true,
                'requete.jdd.observation'=>true,
                'requete.observateur.observation'=>true,
                'requete.organisme.utilisateur'=>true,
                'requete.utilisateur.observation'=>true,
                'visualisation.donnees.brutes'=>true,
                'visualisation.donnees.maille_01'=>true,
                'visualisation.donnees.maille_02'=>true,
                'visualisation.donnees.sensibles'=>true,
            )
        );

        jAcl2DbManager::setRightsOnGroup(
            'naturaliz_profil_3',
            array(
                'requete.spatiale.maille_01'=>true,
                'requete.spatiale.maille_02'=>true,
                'requete.spatiale.cercle'=>true,
                'requete.spatiale.polygone'=>true,
                'requete.spatiale.import'=>true,
                'requete.spatiale.espace.naturel'=>true,
                'requete.jdd.observation'=>true,
                'requete.observateur.observation'=>true,
                'requete.utilisateur.observation'=>true,
                'visualisation.donnees.brutes'=>true,
                'visualisation.donnees.maille_01'=>true,
                'visualisation.donnees.maille_02'=>true,
                'visualisation.donnees.sensibles'=>true,
            )
        );

        jAcl2DbManager::setRightsOnGroup(
            'naturaliz_profil_4',
            array(
                'requete.spatiale.maille_01'=>true,
                'requete.spatiale.maille_02'=>true,
                'requete.spatiale.espace.naturel'=>true,
                'requete.jdd.observation'=>true,
                'requete.observateur.observation'=>true,
                'requete.utilisateur.observation'=>true,
                'visualisation.donnees.brutes'=>true,
                'visualisation.donnees.maille_01'=>true,
                'visualisation.donnees.maille_02'=>true,
                'visualisation.donnees.sensibles'=>true,
            )
        );

        jAcl2DbManager::setRightsOnGroup(
            'naturaliz_profil_5',
            array(
                'requete.spatiale.maille_01'=>true,
                'requete.spatiale.maille_02'=>true,
                'requete.spatiale.espace.naturel'=>true,
                'requete.jdd.observation'=>true,
                'requete.observateur.observation'=>true,
                'visualisation.donnees.brutes'=>true,
                'visualisation.donnees.maille_01'=>true,
                'visualisation.donnees.maille_02'=>true,
            )
        );

        // Add some rights for anonymous
        jAcl2DbManager::addRight('__anonymous', 'requete.spatiale.maille_02');
        jAcl2DbManager::addRight('__anonymous', 'visualisation.donnees.maille_02');

        // Add admin to group naturaliz_profil_1
        jAcl2DbUserGroup::addUserToGroup('admin', 'naturaliz_profil_1');

        // Ajout des droits naturaliz pour le groupe admins
        // On n'utilise surtout pas jAcl2DbManager::setRightsOnGroup car on doit lui passer aussi
        // tous les sujets Lizmap et Jelix, sinon les droits sont vidés
        jAcl2DbManager::addRight('admins', 'occtax.admin.config.gerer');
        jAcl2DbManager::addRight('admins', 'requete.spatiale.maille_01');
        jAcl2DbManager::addRight('admins', 'requete.spatiale.maille_02');
        jAcl2DbManager::addRight('admins', 'requete.spatiale.cercle');
        jAcl2DbManager::addRight('admins', 'requete.spatiale.polygone');
        jAcl2DbManager::addRight('admins', 'requete.spatiale.import');
        jAcl2DbManager::addRight('admins', 'requete.spatiale.espace.naturel');
        jAcl2DbManager::addRight('admins', 'requete.jdd.observation');
        jAcl2DbManager::addRight('admins', 'requete.observateur.observation');
        jAcl2DbManager::addRight('admins', 'requete.organisme.utilisateur');
        jAcl2DbManager::addRight('admins', 'requete.utilisateur.observation');
        jAcl2DbManager::addRight('admins', 'visualisation.donnees.brutes');
        jAcl2DbManager::addRight('admins', 'visualisation.donnees.brutes.selon.diffusion');
        jAcl2DbManager::addRight('admins', 'visualisation.donnees.maille_01');
        jAcl2DbManager::addRight('admins', 'visualisation.donnees.maille_02');
        jAcl2DbManager::addRight('admins', 'visualisation.donnees.sensibles');
        jAcl2DbManager::addRight('admins', 'visualisation.donnees.non.filtrees');
        jAcl2DbManager::addRight('admins', 'export.geometries.brutes.selon.diffusion');

        // Ajouter le droit d'utiliser l'outil de validation en ligne
        jAcl2DbManager::addSubject(
            'validation.online.access',
            'occtax~jacl2.validation.online.access',
            'naturaliz.subject.group'
        );
        jAcl2DbUserGroup::createGroup(
            'naturaliz_validateurs',
            'naturaliz_validateurs'
        );
        jAcl2DbManager::addRight('admins', 'validation.online.access');
        jAcl2DbManager::addRight('naturaliz_validateurs', 'validation.online.access');

        // Ajoute les 2 nouveaux droits pour l'import CSV en ligne
        jAcl2DbManager::addSubject('import.online.access.conformite', 'occtax~jacl2.import.online.access.conformite', 'naturaliz.subject.group');
        jAcl2DbManager::addSubject('import.online.access.import', 'occtax~jacl2.import.online.access.import', 'naturaliz.subject.group');
        jAcl2DbUserGroup::createGroup(
            'naturaliz_importateurs',
            'naturaliz_importateurs'
        );
        jAcl2DbManager::addRight('admins', 'import.online.access.conformite');
        jAcl2DbManager::addRight('admins', 'import.online.access.import');
        jAcl2DbManager::addRight('naturaliz_importateurs', 'import.online.access.conformite');
        jAcl2DbManager::addRight('naturaliz_importateurs', 'import.online.access.import');

    }
}
