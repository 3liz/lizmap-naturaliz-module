<?php

/**
 * @package   lizmap
 * @subpackage occtax
 * @author    Michaël Douchin
 * @copyright 2014 3liz
 * @link      http://3liz.com
 * @license    All rights reserved
 */

class importCtrl extends jController
{

    /**
     * Get the data from the import form
     * and return error or data depending on the status
     */
    function check()
    {
        // Define the object to return
        $return = array(
            'status' => 0,
            'messages' => array(),
            'data' =>  array()
        );
        $rep = $this->getResponse('json');

        // if (!jAcl2::check("import.online.access")) {
        if (!jAcl2::check("validation.online.access")) {
            $return['status'] = 0;
            $return['messages'][] = jLocale::get('occtax~import.form.error.right');
            $rep->data = $return;
            return $rep;
        }

        // Get form
        $form = jForms::get("occtax~import");
        if (!$form) {
            $form = jForms::create("occtax~import");
        }

        // Automatic form check
        $form->initFromRequest();
        if (!$form->check()) {
            $errors = $form->getErrors();
            $return['messages'][] = "Le formulaire n'est pas valide. Veuillez renvoyer votre fichier CSV.";
            $rep->data = $return;
            return $rep;
        }

        // Check the file extension and properties
        $ext = strtolower(pathinfo($_FILES['observation_csv']['name'], PATHINFO_EXTENSION));
        if ($ext != 'csv') {
            $return['messages'][] = 'Fichier CSV requis';
            $rep->data = $return;
            return $rep;
        }

        // Get the CSV file content
        $time = time();
        $csv_target_directory = jApp::varPath('uploads/');
        $csv_target_filename = $time . '_'. $_FILES['observation_csv']['name'];
        $save_file = $form->saveFile('observation_csv', $csv_target_directory, $csv_target_filename);
        if (!$save_file) {
            $return['messages'][] = 'Erreur d\'envoi du fichier CSV';
            $rep->data = $return;
            return $rep;
        }
        // Import library
        jClasses::inc('occtax~occtaxImport');
        $import = new occtaxImport($csv_target_directory.'/'.$csv_target_filename);
        // Check the CSV structure
        list($check, $messages) = $import->checkStructure();
        if (!$check) {
            $return['messages'][] = $messages;
            $rep->data = $return;
            return $rep;
        }

        // Create the temporary tables
        $check = $import->createTemporaryTables();
        if (!$check) {
            $return['messages'][] = 'Impossible de créer les tables temporaires nécessaires au déroulement de l\'import';
            $rep->data = $return;
            return $rep;
        }

        // Import the CSV data into the source temporary table
        $check = $import->saveToSourceTemporaryTable();
        if (!$check) {
            $return['messages'][] = 'Impossible de charger les données du CSV dans la table temporaire';
            $rep->data = $return;
            return $rep;
        }

        // Import the CSV data into the formatted temporary table
        $check = $import->saveToTargetTemporaryTable();
        if (!$check) {
            $return['messages'][] = 'Impossible de formatter les données du CSV dans le format attendu';
            $rep->data = $return;
            return $rep;
        }

        // Validate the data
        // Check not null
        $check_not_null = $import->validateCsvData('not_null');
        if (!is_array($check_not_null)) {
            $return['messages'][] = 'Impossible de vérifier que les valeurs du CSV sont non vides';
            $rep->data = $return;
            return $rep;
        }

        // Check format
        $check_format = $import->validateCsvData('format');
        if (!is_array($check_format)) {
            $return['messages'][] = 'Impossible de vérifier que les valeurs du CSV sont au bon format';
            $rep->data = $return;
            return $rep;
        }

        // Check validity
        $check_conforme = $import->validateCsvData('conforme');
        if (!is_array($check_conforme)) {
            $return['messages'][] = 'Impossible de vérifier que les valeurs du CSV sont conformes au standard';
            $rep->data = $return;
            return $rep;
        }

        $return['status'] = 1;
        $return['data'] = array(
            'not_null'=>$check_not_null,
            'format'=>$check_format,
            'conforme'=>$check_conforme,
        );

        // Clean
        jForms::destroy("occtax~import");
        $import->clean();

        // Return data
        $rep->data = $return;

        return $rep;
    }

}
