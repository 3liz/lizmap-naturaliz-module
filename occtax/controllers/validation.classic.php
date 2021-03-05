<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class validationCtrl extends jController {

    function index() {

        $rep = $this->getResponse('json');

        // Params
        $action = $this->param('validation_action', 'get');

        // Class
        jClasses::inc('occtax~occtaxValidation');
        $validation = new occtaxValidation();

        // Add or remove
        $data = array();
        $status = 'success';
        $message = '';

        if (in_array($action, array('add', 'remove'))) {
            $id = $this->param('id');
            if ($id && !$validation->isValidUuid($id)) {
                $id = null;
            }
            if (empty($id)) {
                $status = 'error';
                $message = jLocale::get("validation.error.wrong.observation.id");
            } else {

                if ($action == 'add') {
                    $data = $validation->addObservationToBasket($id);
                    $message = jLocale::get("validation.add.observation.to.basket.success");
                } else {
                    $data = $validation->removeObservationFromBasket($id);
                    $message = jLocale::get("validation.remove.observation.from.basket.success");
                }
            }
        } else {
            if ($action == 'empty') {
                $data = $validation->emptyValidationBasket();
                $message = jLocale::get("validation.empty.validation.basket.success");
            } else {
                // Get
                $data = $validation->getValidationBasket();
                $message = jLocale::get("validation.get.validation.basket.success");
            }
        }
        if (!is_array($data) && empty($data)) {
            $status = 'error';
            $message = 'An error occured. No data has been fetched';
            $data = array();
        }

        $return = array(
            'status' => $status,
            'message' => $message,
            'data' => $data,
        );
        $rep->data = $return;
        return $rep;
    }



}
