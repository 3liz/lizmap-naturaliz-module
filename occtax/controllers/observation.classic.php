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

        // Get occtaxSearch instance
        jClasses::inc('occtax~occtaxSearchObservation');
        $token = md5( $form->id().time().session_id() );
        $occtaxSearch = new occtaxSearchObservation( $token, $form->getAllData() );
        jForms::destroy('occtax~search');
        jClasses::inc('occtax~occtaxExportSingleObservation');
        $occtaxSearch = new occtaxExportSingleObservation( $token, null );

        // Get data
        $limit = 1;
        $offset = 0;
        try {
            $return = $occtaxSearch->getData( $limit, $offset );
            $fields = $occtaxSearch->getFields();
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
                    $data[$attr] = $line[$i];
                    $i++;
                };
            }
        }

        // Get child data
        $topics = array(
            'commune',
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
                'espace_naturel',
                'sig'
            );
            $topics = array_diff(
                $topics,
                $blackTopics
            );
        }

        $children = array();
        foreach( $topics as $topic ) {
            // Get data for the given topic
            $return = $occtaxSearch->getTopicData( $topic );
            if( !$return )
                continue;

            $children[$topic] = $return;
        }

        $tpl = new jTpl();
        $tpl->assign('data', $data);
        $tpl->assign('children', $children);
        $content = $tpl->fetch('occtax~observation');

        $rep->addContent( $content );

        return $rep;
    }

}
