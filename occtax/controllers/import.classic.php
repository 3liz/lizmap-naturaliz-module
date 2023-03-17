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

        $fichier = jApp::getModulePath('occtax').'install/config/import_observations_csv_template.csv';
        $nom_fichier = 'observations_exemple.csv';
        $mime = 'text/csv';

        $ressource = $this->param('ressource', 'csv');
        if ($ressource == 'pdf') {
            // $nom_fichier = 'Occurrences_de_taxon-v1_2_1_FINALE.pdf';
            $nom_fichier = 'OccTax_v2_COMPLET.pdf';
            $fichier = jApp::getModulePath('occtax').'install/config/'.$nom_fichier;
            $mime = 'application/pdf';
        } elseif ($ressource == 'nomenclature') {
            $fichier = jApp::getModulePath('occtax').'install/config/occtax_nomenclature.xlsx';
            $nom_fichier = 'occtax_nomenclature.xlsx';
            $mime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
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
            'data' =>  array('other'=>array())
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
            $message = "Le formulaire n'est pas valide. Veuillez renvoyer votre fichier CSV.";
            $return['messages'][] = $message;
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
        $csv_target_filename = $time.'_'.$_FILES['observation_csv']['name'];
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
            $return['messages'][] = 'Impossible de créer les tables temporaires nécessaires au déroulement de l\'import (erreur de requête)';
            $rep->data = $return;
            return $rep;
        }

        // Import the CSV data into the source temporary table
        $check = $import->saveToSourceTemporaryTable();
        if (!$check) {
            $return['messages'][] = 'Impossible de charger les données du CSV dans la table temporaire (erreur de requête)';
            $rep->data = $return;
            return $rep;
        }

        // Import the CSV data into the formatted temporary table
        $check = $import->saveToTargetTemporaryTable();
        if (!$check) {
            $return['messages'][] = 'Impossible de formatter les données du CSV dans le format attendu (erreur de requête)';
            $rep->data = $return;
            return $rep;
        }

        // Validate the data
        // Check not null
        $check_not_null = $import->validateCsvData('not_null');
        if (!is_array($check_not_null)) {
            $return['messages'][] = 'Impossible de vérifier que les valeurs du CSV sont non vides (erreur de requête)';
            $rep->data = $return;
            return $rep;
        }

        // Check format
        $check_format = $import->validateCsvData('format');
        if (!is_array($check_format)) {
            $return['messages'][] = 'Impossible de vérifier que les valeurs du CSV sont au bon format (erreur de requête)';
            $rep->data = $return;
            return $rep;
        }

        // Check validity
        $check_conforme = $import->validateCsvData('conforme');
        if (!is_array($check_conforme)) {
            $return['messages'][] = 'Impossible de vérifier que les valeurs du CSV sont conformes au standard (erreur de requête)';
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

        // If we only check, we can clean the data and return the response
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

        // Check that the other fields are correct and not empty
        $organisme_gestionnaire_donnees = (string) $form->getData('organisme_gestionnaire_donnees');
        $libelle_import = (string) $form->getData('libelle_import');
        $date_reception = (string) $form->getData('date_reception');
        $remarque_import = (string) $form->getData('remarque_import');
        $required_data_fields = array(
            'jdd_uid' => 'JDD',
            'organisme_gestionnaire_donnees' => 'Organisme gestionnaire des données',
            'libelle_import' => 'Libellé',
            'date_reception' => 'Date de réception',
            'remarque_import' => 'Remarque'
        );
        $empty_required_data = array();
        $message = "Pour pouvoir importer les données, il faut spécifier des valeurs pour les champs : ";
        foreach ($required_data_fields as $rfield => $rlabel) {
            $rval = $form->getData($rfield);
            if (empty($rval)) {
                $empty_required_data[] = $rlabel ;
            }
        }
        if (count($empty_required_data) > 0) {
            $import->clean();
            $return['messages'][] = $message.implode(', ', $empty_required_data);
            $rep->data = $return;
            return $rep;
        }

        // Get the JDD and cadre data for the given JDD uid
        $jdd_data = $import->getJdd($jdd_uid, 'database');
        if (empty($jdd_data)) {
            $import->clean();
            $message = "Impossible de récupérer les données du jeu de données (JDD) dans la base à partir de son identifiant: ";
            $message .= $jdd_uid;
            $return['messages'][] = $message;
            $rep->data = $return;
            return $rep;
        }

        // Get the logged user login
        $user = \jAuth::getUserSession();
        $login = null; $user_email = '';
        if ($user) {
            $login = $user->login;
            $user_email = $user->email;
        }
        if (!$login) {
            jForms::destroy("occtax~import");
            $import->clean();
            $return['messages'][] = "Impossible de récupérer le login de la personne connectée";
            $rep->data = $return;
            return $rep;
        }

        // Check if the CSV data does not contain observations
        // that are already in the table occtax.observation of the database

        // Check first for the specified JDD
        $check_duplicate = $import->checkCsvDataDuplicatedObservations($jdd_uid, true);
        // Then check against all observations
        $check_duplicate_all = $import->checkCsvDataDuplicatedObservations($jdd_uid, false);
        if (!is_array($check_duplicate) || !is_array($check_duplicate_all)) {
            jForms::destroy("occtax~import");
            $import->clean();
            $return['messages'][] = "Impossible de vérifier si les observations sont en doublon (erreur de requête)";
            $rep->data = $return;
            return $rep;
        }

        if ($check_duplicate[0]->duplicate_count > 0 || $check_duplicate_all[0]->duplicate_count > 0) {
            jForms::destroy("occtax~import");
            $import->clean();
            $message = '';
            if ($check_duplicate[0]->duplicate_count > 0) {
                $message .= $check_duplicate[0]->duplicate_count." données du CSV sont déjà dans la base pour le JDD ".$jdd_uid.'.';
            }
            if ($check_duplicate_all[0]->duplicate_count > 0) {
                $message .= $check_duplicate_all[0]->duplicate_count." données du CSV sont déjà dans la base pour d'autres JDD.";
            }

            $return['messages'][] = $message;
            $return['data']['duplicate_count'] = $check_duplicate[0]->duplicate_count;
            $return['data']['duplicate_ids'] = $check_duplicate[0]->duplicate_ids;
            $return['data']['duplicate_count_all'] = $check_duplicate_all[0]->duplicate_count;
            $return['data']['duplicate_ids_all'] = $check_duplicate_all[0]->duplicate_ids;
            $rep->data = $return;
            return $rep;
        }

        // Check the given validator
        $validateur = $form->getData('validateur');
        if (empty($validateur)) {
            $import->clean();
            $return['messages'][] = 'Le validateur doit être défini, même si aucun niveau de validité n\'est fourni.';
            $rep->data = $return;
            return $rep;
        }

        // Import observations
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = parse_ini_file($localConfig, true);
        $org_transformation = 'Inconnu';
        if (array_key_exists('naturaliz', $ini) && array_key_exists('org_transformation', $ini['naturaliz'])) {
            $org_transformation = $ini['naturaliz']['org_transformation'];
        }
        $import_observation = $import->importCsvIntoObservation(
            $login, $jdd_uid,
            $organisme_gestionnaire_donnees, $org_transformation
        );
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
        $default_email = 'inconnu@acme.org';
        if (array_key_exists('naturaliz', $ini) && array_key_exists('default_email', $ini['naturaliz'])) {
            $default_email = $ini['naturaliz']['default_email'];
        }
        $import_other_data = $import->addImportedObservationPostData(
            $login, $jdd_uid, $default_email,
            trim($libelle_import), $date_reception, trim($remarque_import),
            $user_email, $validateur
        );
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
        $return['messages'][] = "Les observations ont été importées dans la base. Elle seront activées prochainement par l'administrateur.";

        // Clean
        jForms::destroy("occtax~import");
        $import->clean();

        // Return data
        $rep->data = $return;

        return $rep;
    }

}
