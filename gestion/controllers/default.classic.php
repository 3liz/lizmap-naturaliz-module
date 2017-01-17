<?php
/**
* @package   lizmap
* @subpackage gestion
* @author    your name
* @copyright 2011 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class defaultCtrl extends jController {
    /**
    *
    */
    function index() {
        $rep = $this->getResponse('html');

        return $rep;
    }
}

