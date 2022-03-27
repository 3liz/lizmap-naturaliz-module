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
     * Get the template CSV or the Occtax PDF
     *
     */
    function getRessourceFile()
    {
        $rep = $this->getResponse('binary');

        $fichier = jApp::getModulePath('occtax') . 'install/config/import_observations_csv_template.csv';
        $nom_fichier = 'observations_exemple.csv';
        $mime = 'text/csv';

        $ressource = $this->param('ressource', 'csv');
        if ($ressource == 'pdf') {
            $fichier = jApp::getModulePath('occtax') . 'install/config/Occurrences_de_taxon-v1_2_1_FINALE.pdf';
            $nom_fichier = 'Occurrences_de_taxon-v1_2_1_FINALE.pdf';
            $mime = 'application/pdf';
        }

        $rep->fileName = $fichier;
        $rep->outputFileName = $nom_fichier;
        $rep->mimeType = $mime;
        $rep->doDownload = true;
        $rep->deleteFileAfterSending = false;

        return $rep;
    }

    /**
     * Get the data from the import form
     * and return error or data depending on the status
     */
    function check()
    {
        // Define the object to return
        $return = array(
            'action' => 'check',
            'status_check' => 0,
            'status_import' => 0,
            'messages' => array(),
            'data' =>  array()
        );
        $rep = $this->getResponse('json');

        if (!jAcl2::check("import.online.access.conformite")) {
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

        // Check if we must import or only validate the data
        $action = $form->getData('check_or_import');
        if (!in_array($action, array('check', 'import'))) {
            $action = 'check';
        }

        $return['data'] = array(
            'not_null'=>$check_not_null,
            'format'=>$check_format,
            'conforme'=>$check_conforme,
        );

        $return['status_check'] = 1;

        // Only import if it is asked or available for the authenticated user
        if ($action == 'import' && !jAcl2::check("import.online.access.import")) {
            $action = 'check';
        }

        // If we only check, we can clean the data and return the reponse
        if ($action == 'check') {
            $return['action'] = 'check';
            jForms::destroy("occtax~import");
            $import->clean();
            $rep->data = $return;
            return $rep;
        }

        // Go on trying to import the data
        $return['action'] = 'import';

        // We must NOT go on if the check has found some problems
        if (count($check_not_null) || count($check_format) || count($check_conforme)) {
            jForms::destroy("occtax~import");
            $import->clean();
            $return['messages'][] = "Aucune observation n'a été importée car le contrôle a trouvé des erreurs.";
            $rep->data = $return;
            return $rep;
        }

        // Check the uid of the JDD is valid
        $jdd_uid = (string) $form->getData('jdd_uid');
        if (!$import->isValidUuid($jdd_uid)) {
            jForms::destroy("occtax~import");
            $import->clean();
            $return['messages'][] = "L'identifiant SINP du jeu de données n'est pas valide.";
            $rep->data = $return;
            return $rep;
        }

        // Get the JDD and cadre data for the given JDD uid
        $jdd_data = $import->getJdd($jdd_uid, 'database');
        // if (empty($jdd_data)) {
        //     $jdd_data = $import->getJdd($jdd_uid, 'api');
        // }
        if (empty($jdd_data)) {
            jForms::destroy("occtax~import");
            $import->clean();
            $return['messages'][] = "Impossible de récupérer les données du jeu de données dans la base";
            $rep->data = $return;
            return $rep;
        }

        // Get the logged user login
        $user = \jAuth::getUserSession();
        $login = null;
        if ($user) {
            $login = $user->login;
        }
        if (!$login) {
            jForms::destroy("occtax~import");
            $import->clean();
            $return['messages'][] = "Impossible de récupérer le login de la personne connectée";
            $rep->data = $return;
            return $rep;
        }

        // Import observations
        $organisme_responsable = 'PNRM';
        $import_observation = $import->importCsvIntoObservation($login, $jdd_uid, $organisme_responsable);
        if (!$import_observation) {
            // Delete already imported data
            $import->deleteImportedData($jdd_uid);
            jForms::destroy("occtax~import");
            $import->clean();
            $return['messages'][] = "Aucune observation n'a été importée dans la base";
            $rep->data = $return;
            return $rep;
        }

        // Import other data
        $import_other_data = $import->addImportedObservationPostData($login, $jdd_uid);
        if (!$import_other_data) {
            // Delete already imported data
            $import->deleteImportedData($jdd_uid);
            jForms::destroy("occtax~import");
            $import->clean();
            $return['messages'][] = "Une erreur a été rencontrée lors de l'ajout des données tierces (organismes, personnes)";
            $rep->data = $return;
            return $rep;
        }

        // Add detail in the returned object
        $return['status_import'] = 1;
        $return['data']['observations'] = $import_observation;
        $return['data']['other'] = $import_other_data;
        $return['messages'][] = "Les observations ont été importées dans la base. Elle seront activée par l'administrateur.";

        // Clean
        jForms::destroy("occtax~import");
        $import->clean();

        // Return data
        $rep->data = $return;

        return $rep;
    }

}
