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

        $id = $this->param('id');
        if (in_array($action, array('add', 'remove'))) {
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
        } elseif ($action == 'empty') {
            $data = $validation->emptyValidationBasket();
            $message = jLocale::get("validation.empty.validation.basket.success");
        } elseif ($action == 'get') {
                // Get
                $data = $validation->getValidationBasket();
                $message = jLocale::get("validation.get.validation.basket.success");
        } elseif ($action == 'observation_validity') {
            $data = $validation->getObservationValidity($id);
            $message = 'OK';
        } elseif ($action == 'validate') {
            $niv_val = $this->param('niv_val');
            $params = array(

            );
            //$data = $validation->validateObservationsFromBasket($params);
            $data = array('status'=>'success');
            $message = 'OK';
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
