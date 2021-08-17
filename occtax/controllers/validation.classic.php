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

        // Check connected user has a login corresponding to a validator
        $login = Null;
        $user = jAuth::getUserSession();
        if ($user) {
            $login = $user->login;
        }

        //if ($invalid_login) {
            //$status = 'error';
            //$message = 'An error occured. No data has been fetched';
            //$data = array();
        //}

        // Check the authenticated user can use validation
        if (!$login || !jAcl2::checkByUser($login, "validation.online.access")) {
            // Return error
            $return = array(
                'status' => 'error',
                'message' => 'Droit insuffisant pour le module de validation en ligne',
                'data' => array(),
            );
            $rep->data = $return;
            return $rep;
        }

        // Default returned values
        $data = array();
        $status = 'success';
        $message = '';

        // Params
        $action = $this->param('validation_action', 'get');

        // Class pour gérer la validation
        jClasses::inc('occtax~occtaxValidation');
        $validation = new occtaxValidation();

        // Check if the authenticated user has a corresponding item in the occtax.personne table
        $ok = $validation->authenticatedUserIsInPersonTable();
        if (!$ok) {
            $return = array(
                'status' => 'error',
                'message' => jLocale::get("validation.error.no.personne.for.login"),
                'data' => array(),
            );
            $rep->data = $return;
            return $rep;
        }

        // Get identifiant permanent
        $identifiant_permanent = $this->param('identifiant_permanent', '-1');
        if (!$validation->isValidUuid($identifiant_permanent)) {
            $identifiant_permanent = null;
        }

        // Add or remove a single observation in/from the basket
        if (in_array($action, array('add', 'remove'))) {
            if (empty($identifiant_permanent)) {
                $status = 'error';
                $message = jLocale::get("validation.error.wrong.observation.id");
            } else {

                if ($action == 'add') {
                    $data = $validation->addObservationToBasket($identifiant_permanent);
                    $message = jLocale::get("validation.add.observation.to.basket.success");
                } else {
                    $data = $validation->removeObservationFromBasket($identifiant_permanent);
                    $message = jLocale::get("validation.remove.observation.from.basket.success");
                }
            }
        }
        // Empty the validation basket
        elseif ($action == 'empty') {
            $data = $validation->emptyValidationBasket();
            $message = jLocale::get("validation.empty.validation.basket.success");
        }

        // Get the content of the observation basket
        elseif ($action == 'get') {
                // Get
                $data = $validation->getValidationBasket();
                $message = jLocale::get("validation.get.validation.basket.success");
        }

        // Get validation data for a given observation cle_obs id
        elseif ($action == 'observation_validity') {
            $id = $this->intParam('id', -1);
            if (empty($id)) {
                $status = 'error';
                $message = jLocale::get("validation.error.wrong.observation.id");
            } else {
                $data = $validation->getObservationValidity($id);
                $message = 'OK';
            }
        }

        // Get the content of the observation basket
        elseif ($action == 'add_search_to_basket') {
            // Get search token
            $token = $this->param('token');
            $data = $validation->addSearchResultToBasket($token);
            $message = jLocale::get("validation.get.validation.basket.success");
        }

        // Validate all the basket or a single observation
        // We check the given $identifiant_permanent to know which action to run
        elseif ($action == 'validate') {
            $check = true;
            $check_message = array();

            $form = jForms::get("occtax~validation");
            if( !$form )
              $form = jForms::create("occtax~validation");
            $form->initFromRequest();
            if (!$form->check()) {
                $check = false;
                $check_message[] = $form->getErrors();
            } else {
                // Further validate given parameters
                $niv_val = $this->intParam('niv_val', 0);
                if (!is_numeric($niv_val)) {
                    $check = false;
                    $check_message[] = jLocale::get('validation.input.niv_val.error');
                } else {
                    $niv_val = (integer)$niv_val;
                    if ($niv_val <= 0 || $niv_val > 6) {
                        $check = false;
                        $check_message[] = jLocale::get('validation.input.niv_val.error');
                    }
                }
                $producteur = strip_tags(trim($form->getData('producteur')));
                $comm_val = strip_tags(trim($form->getData('comm_val')));
                $nom_retenu = strip_tags(trim($form->getData('nom_retenu')));
                $date_contact = trim($form->getData('date_contact'));

                if (!empty($date_contact)) {
                    $dt = DateTime::createFromFormat("Y-m-d", $date_contact);
                    $date_valide = $dt !== false && !array_sum($dt::getLastErrors());
                    if (!$date_valide) {
                        $check = False;
                        $check_message[] = jLocale::get('validation.input.date_contact.error');
                    }
                }
            }

            // Return error message or run the validation method from class
            if (!$check) {
                $message = jLocale::get('validation.form.validation.input.error');
                $message.= '<ul><li>' . implode('</li><li>', $check_message).'</li></ul>';
                $data = null;
                $status = 'error';
            } else {
                $input_params = array(
                    $niv_val, $producteur, $date_contact, $comm_val, $nom_retenu, $identifiant_permanent
                );
                $data = $validation->validateObservations($input_params);
                // Attention, dans le cas d'un UPDATE (car une ligne existait déjà pour ces observations)
                // dans la table validation_observation pour cet ech_val
                // la méthode validateObservations peut ne rien renvoyer
                if (is_null($data)) {
                    $message = jLocale::get('validation.form.validation.output.error');
                    $data = null;
                    $status = 'error';
                } else {
                    $message = jLocale::get('validation.validate.validation.basket.success');
                }
                // For single observation, get the data so that the JS has the observation id (cle_obs)
                if (is_array($data) && !empty($identifiant_permanent) && $validation->isValidUuid($identifiant_permanent)) {
                    $data = $validation->getObservationValidity($identifiant_permanent, 'identifiant_permanent');
                    $message = jLocale::get('validation.button.validate.observation.success');
                }

            }
        }

        // Return a error if needed
        if (is_null($data)) {
            $status = 'error';
            if (empty(trim($message))) {
                $message = 'An unknown error occured. No data has been fetched';
            }
            $data = array();
        }

        // Return information
        $return = array(
            'status' => $status,
            'message' => $message,
            'data' => $data,
        );
        $rep->data = $return;
        return $rep;
    }



}
