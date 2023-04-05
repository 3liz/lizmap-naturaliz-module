<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class observationCtrl extends jController {


    function __construct( $request ){
        parent::__construct( $request );
    }

    /**
     * Get observation detail
     *
     */
    function getObservation() {

        $rep = $this->getResponse('htmlfragment');
        $return = array();
        $attributes = array();

        // Get form
        $form = jForms::create('occtax~search');

        // Init form from request
        $id = $this->param('id');
        $form->initFromRequest();
        if( $id )
            $form->setData('cle_obs', $id);

        // Get user login
        $login = Null;
        $user = jAuth::getUserSession();
        if ($user) {
            $login = $user->login;
        }

        // Get occtaxSearch instance and token
        jClasses::inc('occtax~occtaxSearchObservation');
        $occtaxSearch = new occtaxSearchObservation( null, $form->getAllData(), Null, $login );
        jForms::destroy('occtax~search');
        $token = $occtaxSearch->getToken();

        // Get specific occtax search for single obs, using the token
        jClasses::inc('occtax~occtaxSearchSingleObservation');
        $occtaxSearchSingleObservation = new occtaxSearchSingleObservation( $token, null, Null, $login );

        // Get data
        $limit = 1;
        $offset = 0;
        try {
            $return = $occtaxSearchSingleObservation->getData( $limit, $offset );
            $fields = $occtaxSearchSingleObservation->getFields();
            $attributes = $fields['display'];
        }
        catch( Exception $e ) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.form.error.query' );
            $rep->data = $return;
            return $rep;
        }

        $data = array();
        if( count( $return ) > 0 ) {
            foreach($return as $line){
                $i = 0;
                // On boucle et ne récupère que les champs display
                foreach($fields['display'] as $attr){
                    if( array_key_exists($i, $line)){
                        $data[$attr] = $line[$i];
                    }
                    else{
                        $data[$attr] = '';
                    }
                    $i++;
                };
            }
        }

        // Decode geojson
        $geostring = json_encode($data['geojson']);
        $data['geojson'] = $geostring;

        \jLog::log(json_encode($data), 'error');

        // Read local config
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);

        // Children to display
        $observation_card_children = array();
        if($observation_card_children = $ini->getValue('observation_card_children', 'naturaliz')){
            $observation_card_children = array_map('trim', explode(',', $observation_card_children));
        }else{
            $observation_card_children = array(
                'commune',
                'departement',
                'maille',
                'espace_naturel',
                'masse_eau',
                'habitat',
                'attribut_additionnel'
            );
        }
        // Remove sensitive children if not enough rights
        if( !jAcl2::check("visualisation.donnees.brutes") ) {
            $blackTopics = array(
                'attribut_additionnel',
                'espace_naturel'
            );
            $observation_card_children = array_diff(
                $observation_card_children,
                $blackTopics
            );
        }

        $children = array();
        foreach( $observation_card_children as $topic ) {
            // Get data for the given topic
            $return = $occtaxSearchSingleObservation->getTopicData( $topic );
            if( !$return )
                continue;
            $children[$topic] = $return;
        }

        // Build content from template
        $tpl = new jTpl();
        $tpl->assign('data', $data);
        $tpl->assign('children', $children);

        // Fields to display ( here again, to manage json properties for descriptif_sujet )
        $observation_card_fields = array();
        if($observation_card_fields = $ini->getValue('observation_card_fields', 'naturaliz')){
            $observation_card_fields = array_map('trim', explode(',', $observation_card_fields));
        }

        // Nomenclature
        $nomenclature = array();
        $sqlnom = "SELECT * FROM occtax.nomenclature";
        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $reqnom = $cnx->query($sqlnom);
        foreach($reqnom as $nom){
            $nomenclature[$nom->champ.'|'.$nom->code] = $nom->valeur;
        }
        $daot = jDao::get('taxon~t_nomenclature', 'naturaliz_virtual_profile');
        foreach($daot->findAll() as $nom){
            $nomenclature[$nom->champ.'|'.$nom->code] = $nom->valeur;
        }

        $tpl->assign('observation_card_fields', $observation_card_fields);
        $tpl->assign('nomenclature', $nomenclature);

        // Get validation status
        $in_basket = false;
        if ($login && jAcl2::check('validation.online.access')) {
            $sql = " SELECT id_sinp_occtax FROM occtax.validation_panier";
            $sql.= " WHERE True";
            $sql.= " AND usr_login = ";
            $sql.= $cnx->quote($login);
            $sql.= " AND id_sinp_occtax = ";
            $sql.= $cnx->quote($data['id_sinp_occtax']);
            $req = $cnx->query($sql);
            foreach($req as $item){
                $in_basket = true;
                break;
            }
        }
        $tpl->assign('in_basket', $in_basket);

        // Get content
        $content = $tpl->fetch('occtax~observation');
        $rep->addContent( $content );

        return $rep;
    }

}
