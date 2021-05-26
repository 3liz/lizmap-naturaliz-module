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
            $check = true;
            $check_message = array();
            // niv_val
            $niv_val = $this->intParam('niv_val', 0);
            if ($niv_val <= 0 || $niv_val > 6) {
                $check = false;
                $check_message[] = jLocale::get('validation.input.niv_val.error');
            }
            $producteur = strip_tags(trim($this->param('producteur')));
            $comm_val = strip_tags(trim($this->param('comm_val')));
            $nom_retenu = strip_tags(trim($this->param('nom_retenu')));

            $date_contact = trim($this->param('date_contact'));
            if (!empty($date_contact)) {
                $dt = DateTime::createFromFormat("Y-m-d", $date_contact);
                $date_valide = $dt !== false && !array_sum($dt::getLastErrors());
                if (!$date_valide) {
                    $check = False;
                    $check_message[] = jLocale::get('validation.input.date_contact.error');
                }
            }

            if (!$check) {
                $message = jLocale::get('validation.form.validation.input.error');
                $message.= '<ul><li>' . implode('</li><li>', $check_message).'</li></ul>';
                $data = array();
                $status = 'error';
            } else {
                $input_params = array(
                    $niv_val, $producteur, $date_contact, $comm_val, $nom_retenu
                );
                $data = $validation->validateObservationsFromBasket($input_params);
                $message = jLocale::get('validation.validate.validation.basket.success');
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
