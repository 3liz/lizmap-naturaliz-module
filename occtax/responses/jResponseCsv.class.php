<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

require_once( jApp::appPath() . '../lib/jelix/core/response/jResponseText.class.php');

class jResponseCsv extends jResponseText {
    /**
    * @var string
    */
    protected $_type = 'csv';

    /**
     * text content
     * @var string
     */
    public $content = '';

    /**
     * data in PHP you want to send
     * @var mixed
     */
    public $data = null;

    /**
     * CSV delimiter
     * @var string
     */
    public $delimiter = ',';

    /**
     * CSV attributes
     * @var array
     */
    public $attributes = array();




    /**
     * output the content with the text/plain mime type
     * @return boolean    true si it's ok
     */
    public function output(){

        if($this->_outputOnlyHeaders){
            $this->sendHttpHeaders();
            return true;
        }

        // Create temporary file
        $_dirname = '/tmp';
        $_tmp_file = tempnam($_dirname, 'wrt');
        if (!($fd = @fopen($_tmp_file, 'wb'))) {
            $_tmp_file = $_dirname . '/' . uniqid('wrt');
            if (!($fd = @fopen($_tmp_file, 'wb'))) {
                throw new jException('jelix~errors.file.write.error', array ($file, $_tmp_file));
            }
        }

        // Write CSV data
        fputcsv($fd, $this->attributes, $this->delimiter);
        // attributes
        foreach ($this->data as $line) {
            // default php csv handle
            fputcsv($fd, $line , $this->delimiter);
        }
        fclose($fd);
        $this->addHttpHeader('Content-Type','text/csv;charset='.jApp::config()->charset,false);
        $this->_httpHeaders['Content-Length'] = filesize ($_tmp_file);
        $this->sendHttpHeaders();
        readfile ($_tmp_file);
        flush();
        unlink($_tmp_file);

        return true;
    }

    /**
     * output errors
     */
    public function outputErrors(){
        header("HTTP/1.0 500 Internal Jelix Error");
        header('Content-Type: text/plain;charset='.jApp::config()->charset);
        echo jApp::coord()->getGenericErrorMessage();
    }
}
