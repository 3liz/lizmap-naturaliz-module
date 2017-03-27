<?php
class gestionFilterListener extends jEventListener{

    function ongetOcctaxFilters ($event) {
        $filter = $this->getWhereClauseDemande();
        $event->add( $filter );
    }

    private function getWhereClauseDemande(){
        $filter = '';
        $table_demandes = array();
        $cnx = jDb::getConnection();

        // Get user info
        $user = jAuth::getUserSession();
        $login = $user->login;

        // Get demande for user
        $dao_demande = jDao::get('gestion~demande');
        $demandes = $dao_demande->findByLogin($login);
        $actives_demandes = $dao_demande->findActiveDemandesByLogin($login);

        foreach($demandes as $demande){
            $sql_demande = array();

            // First build occtax search with demande params
            $dparams = array();
            if($demande->cd_ref)
                $dparams['cd_nom'] = explode( ',', trim($demande->cd_ref, '{}') );
            if($demande->group1_inpn)
                $dparams['group1_inpn'] = explode( ',', trim($demande->group1_inpn, '{}') );
            if($demande->group2_inpn)
                $dparams['group2_inpn'] = explode( ',', trim($demande->group2_inpn, '{}') );

            jClasses::inc('occtax~occtaxSearchObservation');
            $dsearch = new occtaxSearchObservation( null, $dparams, 1 );
            $sql_demande[] = preg_replace(
                '/WHERE +True( +AND +)?/i',
                '',
                $dsearch->getWhereClause()
            );

            // Add geometry filter if set
            if($demande->geom){
                // Get SRID
                $localConfig = jApp::configPath('localconfig.ini.php');
                $ini = new jIniFileModifier($localConfig);
                $srid = $ini->getValue('srid', 'naturaliz');
                if( !$srid )
                    $srid = 4326;
                $cnx = jDb::getConnection();
                $sql_geom = ' ST_Intersects(o.geom, ST_GeomFromText(' . $cnx->quote($demande->geom) . ', '. $srid .')) ' ;
                $sql_demande[] = $sql_geom;
            }

            // Add validite filter
            if($demande->validite_niveau){
                $sql_demande[] = ' validite_niveau = ANY (' . $cnx->quote($demande->validite_niveau) .'::text[] )';
            }

            // Add validity dates
            if($demande->date_validite_min){
                $sql_demande[] = ' ' . $cnx->quote($demande->date_validite_min) . '::date <= now()::date' ;
            }
            if($demande->date_validite_max){
                $sql_demande[] = ' now()::date <= ' . $cnx->quote($demande->date_validite_max) . '::date ' ;
            }

            // Build full sql for this demand
            if(count($sql_demande) > 0){
                $table_demandes[] = ' ( ' . implode( ' AND ', $sql_demande) . ' ) ';
            }

        }
        if( count($table_demandes)>0 ){
            $filter = implode( ' OR ', $table_demandes);
            $filter = ' AND ( ' . $filter . ' ) ';
        }else{
            // Remove all rights to see any observation if the user has no line in demande table, and is not admin
            if( !jAcl2::check("occtax.admin.config.gerer") ){
                $filter = ' AND False ';
            }
        }
//jLog::log($filter);


        return $filter;
    }


}
?>
