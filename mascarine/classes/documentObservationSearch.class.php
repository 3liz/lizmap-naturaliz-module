<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    René-Luc D'Hont
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class documentObservationSearch {

    private $id = Null;

    private $params = array();

    private $imageUrl = '';

    private $recordsTotal = Null;

    protected $returnFields = array(
      'document',
      'type_document',
      'link_document',
      'size_document',
      'remove_document'
    );

    protected $tplFields = array(
      'link_document' => '<a href="{jurl \'mascarine~observation:document\',array(\'id_obs\'=>$line->id_obs,\'document\'=>$line->document)}" title="{$line->nom_document}" target="_blank">{$line->nom_document|truncate:25:\'...\':true}</a>',
      'remove_document' => '<a href="{jurl \'mascarine~edit_obs:removeDocument\',array(\'id_obs\'=>$line->id_obs,\'document\'=>$line->document)}" target="_blank" class="remove"><i class="icon-trash"></a>'
    );

    protected $row_id = 'document';

    protected $row_label = Null;

    protected $displayFields = array(
      'type_document' => array( 'type' => 'string', 'sortable' => "true"),
      'link_document' => array( 'type' => 'string', 'sortable' => "0"),
      'size_document' => array( 'type' => 'string', 'sortable' => "true"),
      'remove_document' => array( 'type' => 'string', 'sortable' => "0")
    );

    protected $labelFields = array(
      'type_document' => array(
        'dao'=>'mascarine~nomenclature',
        'property'=>'valeur'
      )
    );

    public function __construct ($id, $params=Null) {

        $this->id = $id;
        $this->params = $params;

        // Get the number of total records
        if( !$this->recordsTotal )
            $this->setRecordsTotal();

    }

    /**
     * Get search id
    */
    public function id(){
        return $this->id;
    }

    /**
     * Get search parameters
    */
    public function getParams(){
      return $this->params;
    }

    /**
    * Get search fields properties
    */
    public function getFields(){
        return array(
            'return' => $this->returnFields,
            'row_id' => $this->row_id,
            'row_label' => $this->row_label,
            'display' => $this->displayFields
        );
    }

    /**
     * Get the number of records returned
    */
    public function getRecordsTotal(){
        return $this->recordsTotal;
    }

    /**
    * Calculate the total number of records
    * and set the object property
    */
    function setRecordsTotal() {
        if ( !jAcl2::check( 'observation.creer' ) )
            $this->recordsTotal = 0;
        else {
            $records = 0;
            $docDir = jApp::varPath("documents");
            if ( is_dir( $docDir ) ) {
                $obsDir = jApp::varPath("documents/".$this->id);
                if ( is_dir( $obsDir ) ) {
                    if ( $dh = opendir( $obsDir ) ) {
                        while (($file = readdir($dh)) !== false) {
                            $filePath = jApp::varPath("documents/".$this->id."/".$file);
                            if ( is_file( $filePath ) )
                              $records += 1;
                        }
                    }
                    closedir($dh);
                }
            }
            $this->recordsTotal = $records;
            $projects = Array();
        }
    }

    /**
    * Search observation filtered by given parameters
    * @param $offset Offset for the query. Default 0
    * @param $limit Limit for the query. Default 20
    * @return List of matching taxons
    */
    function getData( $limit=20, $offset=0 ) {
        if ( !jAcl2::check( 'observation.creer' ) )
          return array();

        $data = array();
        $docDir = jApp::varPath("documents");
        if ( is_dir( $docDir ) ) {
            $obsDir = jApp::varPath("documents/".$this->id);
            if ( is_dir( $obsDir ) ) {
                if ( $dh = opendir( $obsDir ) ) {
                    $tools = jClasses::getService('lizmap~tools');
                    while (($file = readdir($dh)) !== false) {
                        $filePath = jApp::varPath("documents/".$this->id."/".$file);
                        if ( is_file( $filePath ) ) {
                            $explode = explode('_', basename($file));
                            $fileType = $explode[0];
                            // nom : on enlève l'id_obs et le type pour affichage
                            $fileNom = substr($file, strlen($fileType.'_'));
                            // taille
                            $fileTaille = $tools->displayFileSize($filePath);

                            $data[] = (object) array(
                                'id_obs'=>$this->id,
                                'document'=>basename($file),
                                'type_document'=>$fileType,
                                'nom_document'=>$fileNom,
                                'size_document'=>$fileTaille
                            );
                        }
                    }
                }
                closedir($dh);
            }
        }

        $d = array();
        // Get fields from result
        foreach( $data as $line ) {
            $item = array();
            // Get fields from result
            foreach( $this->returnFields as $field ) {
                if( property_exists( $line, $field ) and !array_key_exists($field, $this->tplFields) ) {
                    if ( array_key_exists($field, $this->labelFields) ) {
                        $dao = jDao::get( $this->labelFields[$field]['dao'] );
                        $f = null;
                        if ( $this->labelFields[$field]['dao'] == 'mascarine~nomenclature' )
                          $f = $dao->get( $field, $line->$field );
                        else
                          $f = $dao->get( $line->$field );
                        $prop = $this->labelFields[$field]['property'];
                        $item[] = $f->$prop;
                    } else
                      $item[] = $line->$field;
                }
                // Get template field
                if ( array_key_exists($field, $this->tplFields) ) {
                    $template = $this->tplFields[$field];
                    $tpl = new jTpl();
                    $assign = array();
                    if( $field == 'illustration' ){
                        $illustrationPath = '/css/illustrations/' . $line->cd_nom. '.jpg';
                        $imageUrl = '';
                        if( file_exists( jApp::wwwPath() . $illustrationPath) )
                            $illustration = jApp::wwwPath() . $illustrationPath;
                        else
                            $illustration = '';
                        $assign['illustration'] = $illustration;
                    }

                    $assign['line'] = $line;
                    $tpl->assign( $assign );
                    $val = $tpl->fetchFromString($template, 'html');
                    $item[] = $val;
                }
            }

            $d[] = $item;
        }

        $data = $d;
        return $data;
    }
}
