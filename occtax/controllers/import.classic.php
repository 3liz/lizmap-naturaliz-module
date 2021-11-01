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
            'msg' => array(),
            'data' =>  array()
        );
        $rep = $this->getResponse('json');

        if (!jAcl2::check("import.online.access")) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get('occtax~import.form.error.right');
            $rep->data = $return;
            return $rep;
        }

        // Get form
        $form = jForms::get("occtax~import");
        if (!$form)
            $form = jForms::create("occtax~import");

        // Automatic form check
        $form->initFromRequest();
        if (!$form->check()) {
            $return['msg'] = $form->getErrors();
            $rep->data = $return;
            return $rep;
        }

        // Check the file extension and properties
        $ext = strtolower(pathinfo($_FILES['observations']['name'], PATHINFO_EXTENSION));
        if ($ext != 'csv') {
            $return['msg'][] = 'Fichier CSV requis';
            $rep->data = $return;
            return $rep;
        }

        // Get the CSV file content
        $time = time();
        $csv_file = jApp::varPath('uploads/' . $time . '_' . $_FILES['observations']['name']);
        $form->saveFile('observations', $csv_file);

        // Import library
        jClasses::inc('occtax~occtaxGeometryChecker');
        $import = new occtaxImport($csv_file);

        // Check the CSV structure
        list($check, $message) = $import->checkStructure();
        if (!$check) {
            $return['msg'][] = $message;
            $rep->data = $return;
            return $rep;
        }

        // Parse data
        $import->setData();

        // Import the CSV data into a temporary table
        $import->saveToTemporayTable();

        // Validate the data

        // Clean
        jForms::destroy("occtax~import");
        $import->clean();

        // Return data
        $rep->data = $return;

        return $rep;
    }

}
