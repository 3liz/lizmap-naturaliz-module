<?php
class gestionFilterListener extends jEventListener{

    function ongetOcctaxFilters ($event) {
        // Get user info
        $login = $event->getParam('login');

        $filter = $this->getWhereClauseDemande($login);
        $event->add( $filter );
    }

    private function getWhereClauseDemande($login){
        if (!$login) {
            return '';
        }

        // Create virtual profile
        $defaultProfile = jProfiles::get('jdb', 'default');
        $search_path = '';
        if (array_key_exists('search_path', $defaultProfile)) {
            $search_path = $defaultProfile['search_path'];
        }
        if (empty(trim($search_path))) {
            $search_path = 'public';
        }
        foreach (array('taxon','sig','occtax','gestion') as $schema) {
            if (!preg_match( '#'.$schema.'#', $search_path )) {
                $search_path.= ','.$schema;
            }
        }
        $jdbParams = array(
            'driver' => 'pgsql',
            'host' => $defaultProfile['host'],
            'port' => (int) $defaultProfile['port'],
            'database' => $defaultProfile['database'],
            'user' => $defaultProfile['user'],
            'password' => $defaultProfile['password'],
            'search_path' => $search_path,
            'timeout'=> '120',
        );
        $profile = 'naturaliz_virtual_profile';
        jProfiles::createVirtualProfile('jdb', $profile, $jdbParams);

        $filter = '';
        $table_demandes = array();
        $cnx = jDb::getConnection('naturaliz_virtual_profile');

        // Get demande for user
        $dao_demande = jDao::get('gestion~demande', 'naturaliz_virtual_profile');
        //$demandes = $dao_demande->findByLogin($login);
        $actives_demandes = $dao_demande->findActiveDemandesByLogin($login);

        $filter_method = 'a';
        $observation_column_prefix = 'o';
        if ($filter_method == 'b' or $filter_method == 'c') {
            $observation_column_prefix = 'vo';
        }
        //foreach($demandes as $demande){
        foreach($actives_demandes as $demande){
            $sql_demande = array();

            // Add geometry filter if set
            if ($demande->geom) {
                // Get SRID
                $localConfig = jApp::configPath('naturaliz.ini.php');
                $ini = new jIniFileModifier($localConfig);
                $srid = $ini->getValue('srid', 'naturaliz');
                if( !$srid )
                    $srid = 4326;
                $cnx = jDb::getConnection('naturaliz_virtual_profile');
                // method a or b: use ST_GeomFromText, which si faster
                if ($filter_method == 'a' or $filter_method == 'b') {
                    $sql_geom = 'ST_Intersects(
                        '.$observation_column_prefix.'.geom,
                        ST_GeomFromText('.$cnx->quote($demande->geom).', '.$srid.')
                    )' ;
                }
                // d test: use subquery on gestion.demand: very slow for queries with aggregation (count, etc.)
                if ($filter_method == 'd') {
                    $sql_geom = 'ST_Intersects(
                        '.$observation_column_prefix.'.geom,
                        (SELECT geom FROM gestion.demande WHERE id ='.$demande->id.' LIMIT 1)
                    )' ;
                }
                // c test: use a JOIN inside subquery with ST_Intersects(o.geom, d.geom) AND d.id = X)
                // no need to add the intersects filter in the WHERE clause since it is done in JOIN
                if ($filter_method != 'c') {
                    $sql_demande[] = $sql_geom;
                }

            }

            // Add validity dates
            if ($demande->date_validite_min) {
                $sql_demande[] = $cnx->quote($demande->date_validite_min).'::date <= now()::date' ;
            }
            if ($demande->date_validite_max) {
                $sql_demande[] = 'now()::date <= '.$cnx->quote($demande->date_validite_max).'::date' ;
            }

            // Add critere_additionnel
            if (!empty(trim($demande->critere_additionnel))) {
                $sql_demande[] = '( '.$demande->critere_additionnel.' )';
            }

            // Build full sql for this demand
            // Join all criterias with AND
            if (count($sql_demande) > 0) {

                // Build SQL depending of chosen method
                if ($filter_method == 'a') {
                    // a: where clause are directly used on main observation table o.
                    $sql_demand_text = '
                    ( '.implode(
                        '
                        AND
                        ',
                        $sql_demande
                    ).'
                    )
                    ';
                } elseif ($filter_method == 'b') {
                    // b: use a subquery. it has proven better perd than a
                    $sql_demand_text = '
                    o.cle_obs IN (
                    SELECT cle_obs
                    FROM occtax.vm_observation vo
                    WHERE True AND
                    '.implode(
                        '
                        AND
                        ',
                        $sql_demande
                    ).'
                    )
                    ';
                } elseif ($filter_method == 'c') {
                    $sql_demand_text = '
                    o.cle_obs IN (
                    SELECT vo.cle_obs
                    FROM occtax.vm_observation vo';
                    if ($demande->geom) {
                        $sql_demand_text .= '
                        JOIN gestion.demande d
                        ON d.id = '.$demande->id.'
                        AND ST_Intersects(vo.geom, d.geom)
                        ';
                    }
                    $sql_demand_text.= '
                    WHERE True AND
                    '.implode(
                        '
                        AND
                        ',
                        $sql_demande
                    ).'
                    )
                    ';
                } elseif ($filter_method == 'd') {
                    $sql_demand_text = '
                    ( '.implode(
                        '
                        AND
                        ',
                        $sql_demande
                    ).'
                    )
                    ';
                } else {
                    // unknown method: no filter applied
                    $sql_demand_text = Null;
                }
                if (!empty($sql_demand_text)) {
                    $table_demandes[] = $sql_demand_text;
                }
            }
        }

        // Gather SQL of all demands WITH OR
        if( count($table_demandes) > 0 ){
            // Join sql of each demand with OR
            $sub_filter = implode(
                '
                OR
                ',
                $table_demandes
            );
            // Final filter is an AND to the demands sub_filter
            $filter = '
            AND (
            '.$sub_filter.'
            ) ';
        }else{
            // Remove all rights to see any observation if the user has no line in demande table, and is not admin
            if( !jAcl2::checkByUser($login, "visualisation.donnees.non.filtrees") ){
                $filter = ' AND False ';
            }
        }
//jLog::log($filter);
        return $filter;
    }

}
?>
