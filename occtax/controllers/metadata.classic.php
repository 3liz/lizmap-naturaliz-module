<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class metadataCtrl extends jController
{
    public function index()
    {
        $rep = $this->getResponse('htmlfragment');

        // Params
        $mdType = $this->param('type', 'jdd');
        if (!in_array($mdType, array('jdd', 'cadre'))) {
            $mdType = 'jdd';
        }
        $mdId = $this->param('id', '-1');
        $url = null;
        $jdds = null;
        $cadre = null;

        // We check the given ID is valid
        if (preg_match('#^[a-zA-Z0-9_-]+$#', $mdId)) {
            if ($mdType == 'jdd') {
                // Get the JDD data
                $dao_jdd = jDao::get('occtax~jdd', 'naturaliz_virtual_profile');
                $jdd = $dao_jdd->get($mdId);

                // Get the related cadre
                if ($jdd) {
                    $url = $jdd->url_fiche;
                    $jdds = array($jdd);
                    $dao_cadre = jDao::get('occtax~cadre', 'naturaliz_virtual_profile');
                    $cadre = $dao_cadre->get($jdd->jdd_cadre);
                } else {
                    $jdds = null;
                    $cadre = null;
                }

            } else {
                // Get the cadre data
                $dao_cadre = jDao::get('occtax~cadre', 'naturaliz_virtual_profile');
                $cadre = $dao_cadre->get($mdId);

                // Get the related jdds
                if ($cadre) {
                    $url = $cadre->url_fiche;
                    $dao_jdd = jDao::get('occtax~jdd', 'naturaliz_virtual_profile');
                    $conditions = jDao::createConditions();
                    $conditions->addCondition('jdd_cadre', '=', $mdId);
                    $jdds = $dao_jdd->findBy($conditions);
                } else {
                    $jdds = null;
                }
            }
        }

        // Build content from template
        $tpl = new jTpl();
        $tpl->assign('type', $mdType);
        $tpl->assign('url', $url);
        $tpl->assign('jdds', $jdds);
        $tpl->assign('cadre', $cadre);

        // Get content
        $content = $tpl->fetch('occtax~metadata');
        $rep->addContent($content);

        return $rep;
    }
}
