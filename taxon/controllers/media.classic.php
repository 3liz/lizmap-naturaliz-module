<?php
/**
* @package   lizmap
* @subpackage taxon
* @author    Michael Douchin
* @copyright 2022 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class mediaCtrl extends jController {
    /**
    * Get the data about the given taxon ID
    *
    * Returns a JSON describing the medias to download
    */
    function getMedias() {
        $rep = $this->getResponse('json');
        $cd_ref = $this->intParam('cd_ref');

        // Get INPN images
        jClasses::inc('taxon~mediaManagerINPN');
        $mediaManager = new mediaManagerINPN($cd_ref);
        $media = $mediaManager->getMediaInformation();

        $rep->data = $media;

        return $rep;
    }

    /**
     * Get a specific media image
     *
     * If the image is not yet in the cache
     * it is stored in the FTP upload directory
     * then sent back.
     * This method redirect to the correct URL
     */
    function getMedia() {

        $rep = $this->getResponse('redirectUrl');
        $cd_ref = $this->intParam('cd_ref');
        $token = $this->param('token');

        // Get INPN images
        jClasses::inc('taxon~mediaManagerINPN');
        $mediaManager = new mediaManagerINPN($cd_ref);
        $mediaUrl = $mediaManager->getMediaUrl($token);

        $rep->url = $mediaUrl;

        return $rep;
    }
}
