<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

require_once( jApp::appPath() . '../lib/jelix/core/jResponse.class.php');

class jResponseGeoJson extends jResponse {

    /**
    * @var string
    */
    protected $_type = 'geojson';

    /**
     * data in PHP you want to send
     * @var mixed
     */
    public $data = null;

    /**
     * options bitmask for json_encode()
     * @var int
     */
    public $options = 0;

    /**
     * geometry column
     * @var string
     */
    public $geometryColumn = 'geojson';

    /**
     * Geojson attributes
     * @var array
     */
    public $attributes = array();

    /**
     * Output file name
     * @var string
     */
    public $outputFileName = 'export.geojson';


    public function output(){

        if($this->_outputOnlyHeaders){
            $this->sendHttpHeaders();
            return true;
        }

        $this->_httpHeaders['Content-Type'] = "application/json";


        // Création de l'objet qui sera transformé en json
        $json = new stdClass();
        $json->type = 'FeatureCollection';

        $features = array();
        $geometryColumnIndex = array_search($this->geometryColumn, $this->attributes );

        foreach($this->data as $line){

            // creation d'un feature
            $feature = new stdClass();
            $feature->type = 'Feature';

            // géométrie
            $geometry = $line[$geometryColumnIndex];
            $feature->geometry = $geometry;

            // propriétés
            $properties = new stdClass();
            $i = 0;
            foreach($this->attributes as $attr){
                if( $i != $geometryColumnIndex ){
                    $properties->$attr = $line[$i];
                }
                $i++;
            }
            $feature->properties = $properties;

            // ajout de la feature à l'objet $features
            $features[] = $feature;
        }
        // ajout de features à l'objet $json
        $json->features = $features;
        $content = json_encode($json, $this->options);

        // Create temporary file
        $_dirname = '/tmp';
        $_tmp_file = tempnam($_dirname, 'wrt');
        if (!($fd = @fopen($_tmp_file, 'wb'))) {
            $_tmp_file = $_dirname . '/' . uniqid('wrt');
            if (!($fd = @fopen($_tmp_file, 'wb'))) {
                throw new jException('jelix~errors.file.write.error', array ($file, $_tmp_file));
            }
        }
        fwrite($fd, $content);
        fclose($fd);

        $this->_httpHeaders['Content-length'] = filesize ($_tmp_file);
        $this->addHttpHeader('Content-Disposition', 'attachment; filename="'.str_replace('"','\"',$this->outputFileName).'"', false);
        $this->addHttpHeader('Content-Description','File Transfert', false);
        $this->addHttpHeader('Content-Transfer-Encoding','binary', false);
        $this->addHttpHeader('Pragma','public', false);
        $this->addHttpHeader('Cache-Control','maxage=3600', false);

        $this->sendHttpHeaders();
        readfile ($_tmp_file);
        flush();
        unlink($_tmp_file);
        return true;
    }

    public function outputErrors(){

        $message = array();
        $message['errorMessage'] = jApp::coord()->getGenericErrorMessage();
        $e = jApp::coord()->getErrorMessage();
        if($e){
            $message['errorCode'] = $e->getCode();
        }else{
            $message['errorCode'] = -1;
        }
        $this->clearHttpHeaders();
        $this->_httpStatusCode ='500';
        $this->_httpStatusMsg ='Internal Server Error';
        $this->_httpHeaders['Content-Type'] = "application/json";
        $content = json_encode($message);
        $this->_httpHeaders['Content-length'] = strlen($content);
        $this->sendHttpHeaders();
        echo $content;
    }
}

