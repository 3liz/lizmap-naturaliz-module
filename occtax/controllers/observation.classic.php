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

        // Get occtaxSearch instance and token
        jClasses::inc('occtax~occtaxSearchObservation');
        $occtaxSearch = new occtaxSearchObservation( null, $form->getAllData() );
        jForms::destroy('occtax~search');
        $token = $occtaxSearch->getToken();

        // Get specific occtax search for single obs, using the token
        jClasses::inc('occtax~occtaxSearchSingleObservation');
        $occtaxSearchSingleObservation = new occtaxSearchSingleObservation( $token, null );

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

        // Get child data
        $topics = array(
            'commune',
            'departement',
            'maille',
            'espace_naturel',
            'masse_eau',
            'habitat',
            'attribut_additionnel'
        );

        // Remove sensitive data if not enough rights
        if( !jAcl2::check("visualisation.donnees.brutes") ) {
            $blackTopics = array(
                'attribut_additionnel',
                'espace_naturel'
            );
            $topics = array_diff(
                $topics,
                $blackTopics
            );
        }

        $children = array();
        foreach( $topics as $topic ) {
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

        // Fields to display ( here again, to manage json properties for descriptfi_sujet )
        $localConfig = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $observation_card_fields = array();
        if($observation_card_fields = $ini->getValue('observation_card_fields', 'occtax')){
            $observation_card_fields = array_map('trim', explode(',', $observation_card_fields));
        }
        $tpl->assign('observation_card_fields', $observation_card_fields);

        // Get content
        $content = $tpl->fetch('occtax~observation');
        $rep->addContent( $content );

        return $rep;
    }

}
