<?php

/**
 * @package   lizmap
 * @subpackage taxon
 * @author    Michael Douchin
 * @copyright 2011 3liz
 * @link      http://3liz.com
 * @license    All rights reserved
 */

class mediaManagerINPN
{
    protected $baseUrl = 'https://taxref.mnhn.fr/api/taxa/%s/media';
    protected $mediaDownloadUrl = 'https://taxref.mnhn.fr/api/media/download/thumbnail/';
    protected $source = 'inpn';
    protected $cd_nom = null;
    protected $cd_ref = null;
    protected $resourceUrl = null;
    protected $repository = null;
    protected $project = null;

    /**
     * Set up the instance properties
     */
    function __construct($cd_ref)
    {
        $this->cd_ref = $cd_ref;
        $this->ressourceUrl = sprintf($this->baseUrl, $this->cd_ref);

        // Get Occtax default repository and project
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = parse_ini_file($localConfig, true);
        $repository = null;
        $project = null;
        if (array_key_exists('naturaliz', $ini) && array_key_exists('defaultRepository', $ini['naturaliz'])) {
            $repository = $ini['naturaliz']['defaultRepository'];
        }
        if (array_key_exists('naturaliz', $ini) && array_key_exists('defaultProject', $ini['naturaliz'])) {
            $project = $ini['naturaliz']['defaultProject'];
        }
        $this->repository = $repository;
        $this->project = $project;
    }

    /**
     * Return the data when there is an error
     */
    private function response($status = 'success', $message = '', $data = null)
    {
        $error = array(
            'status' => $status,
            'message' => $message,
            'data' => $data
        );

        return $error;
    }


    /**
     * Get a media from the external API
     * or the cache if it is present
     *
     * @param integer $id Media id
     *
     */
    public function getMediaUrl($id, $source)
    {
        // Check parameters
        if(!in_array($source, array('inpn', 'local'))) {
            $source = 'local';
        }

        // Get the api URL from the database
        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $sql = "
            SELECT *
            FROM taxon.medias
            WHERE cd_ref = $1
            AND source = $2
            AND id_origine = $3
        ";
        $resultset = $cnx->prepare($sql);
        $params = array(
            $this->cd_ref,
            $source,
            $id
        );
        $resultset->execute($params);
        $getMedia = $resultset->fetchAll();
        $url = null;
        foreach ($getMedia as $media) {
            // We check a path is already given
            if ($media->media_path && preg_match('#^(\.{0,2}/)?media#', $media->media_path)) {
                $url = jUrl::getFull(
                    'view~media:getMedia',
                    array(
                        'repository' => $this->repository,
                        'project' => $this->project,
                        'path' => $media->media_path
                    )
                );
                return $url;
            }
            $url = $media->url_origine;
        }

        // Store and send back the media
        if ($url && $source == 'inpn') {
            $url = $this->storeInpnMedia($id, $url);
        }

        return $url;
    }

    /**
     * Get the medias for the given taxon
     *
     * We get the list of medias from several sources
     * like database and API
     */
    public function getMediaInformation()
    {

        if (!is_int($this->cd_ref)) {
            return $this->response(
                'error',
                'Le cd_ref doit être un entier',
                null
            );
        }

        // Prepare the object
        $mediaData = array(
            'cd_ref' => $this->cd_ref,
            'source' => $this->source,
        );

        // Get local media
        $databaseMedias = $this->getMediaListFromDatabase('local');

        // Get media from API
        $inpnMedias = $this->getMediaInformationFromAPI();
        if (count($inpnMedias) == 0) {
            \jLog::log('Get media from database, source inpn', 'error');
            $inpnMedias = $this->getMediaListFromDatabase('inpn');
        }

        // Compute
        $medias = array();
        foreach ($databaseMedias as $media) {
            $medias[] = $media;
        }
        foreach ($inpnMedias as $media) {
            $medias[] = $media;
        }
        $mediaData['medias'] = $medias;

        return $this->response(
            'success',
            null,
            $mediaData
        );
    }

    /**
     * Search for data in the taxon.medias table
     * and return the list of medias.
     *
     * @param string $source If we must retrieve inpn or local data
     *
     * @return array $medias The medias for this taxon
     */
    private function getMediaListFromDatabase($source = 'local')
    {
        if (!in_array($source, array('inpn', 'local'))) {
            $source = 'local';
        }

        // Get information from the database
        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $sql = "
            SELECT *
            FROM taxon.medias
            WHERE cd_ref =
        " . $this->cd_ref . "
            AND source =
        " . $cnx->quote($source);
        $getMedias = $cnx->query($sql);
        $medias = array();
        foreach ($getMedias as $media) {
            // Set the media information
            $item = array(
                'cd_nom' => $media->cd_nom,
                'cd_ref' => $media->cd_ref,
                'id_origine' => $media->id_origine,
                'url_origine' => $media->url_origine,
                'auteur' => $media->auteur,
                'titre' => $media->titre,
                'licence' => $media->licence,
                'principal' => $media->principal,
            );
            $mediaUrl = jUrl::getFull(
                'view~media:getMedia',
                array(
                    'repository' => $this->repository,
                    'project' => $this->project,
                    'path' => $media->media_path
                )
            );
            $item['url'] = $mediaUrl;
            $medias[] = $item;
        }

        return $medias;
    }

    /**
     * Download the information about the media
     * and parse the data to a pivot format
     *
     * @return array The medias from the API
     */
    private function getMediaInformationFromAPI()
    {
        if (!is_int($this->cd_ref)) {
            return array();
        }

        $url = $this->ressourceUrl;
        $context = stream_context_create(array(
            'http' =>
            array(
                'timeout' => 2,  // 2 seconds
            )
        ));
        $content = file_get_contents($url, false, $context);

        if (!$content) {
            return array();
        }

        // Parse the data
        $medias = $this->parseApiMedias($content);

        return $medias;
    }

    /**
     * Insert a new media item in the database
     *
     * @param array $media The media item
     * @param string $source The media source : inpn or local
     */
    private function insertMedia($media, $source = 'inpn')
    {
        // Insert data in the database
        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $sql = "
            INSERT INTO taxon.medias (
                cd_nom, cd_ref, principal,
                source, id_origine, url_origine,
                media_path, titre, auteur, licence
            ) VALUES (
                $1, $2, $3,
                $4, $5, $6,
                $7, $8, $9, $10
            )
            ON CONFLICT ON CONSTRAINT taxon_media_unique
            DO NOTHING
        ";
        $resultset = $cnx->prepare($sql);
        $params = array(
            $media['cd_nom'], $media['cd_ref'], 'False',
            $source, $media['id_origine'], $media['url_origine'],
            $media['media_path'], $media['titre'], $media['auteur'], $media['licence']
        );
        $resultset->execute($params);
    }

    /**
     * Read the media information downloaded from
     * the external server and return the formated object
     *
     * @param string $data JSON information data
     *
     * @return array $media The formatted media
     */
    private function parseApiMedias($json)
    {
        // Parse the JSON content
        $data = json_decode($json);
        if (!$data) {
            return array();
        }

        // Get the list of medias
        $medias = array();
        if (
            property_exists($data, '_embedded') && property_exists($data->_embedded, 'media')
            && count($data->_embedded->media)  > 0
        ) {
            foreach ($data->_embedded->media as $media) {
                // Get the media information
                $item = array(
                    'cd_ref' => $media->taxon->referenceId,
                    'cd_nom' => $media->taxon->id,
                    'id_origine' => $media->id,
                    'url_origine' => $media->_links->thumbnailFile->href,
                    'auteur' => $media->copyright,
                    'titre' => $media->title,
                    'licence' => $media->licence,
                    'principal' => null,
                    'media_path' => null,
                );

                // if there is a corresponding file in the serevr
                // add it in the media_path
                list($mediaFtpDirectory, $mediaRelativePath, $mediaFullDirectory, $mediaFullPath) = $this->computeRelativeMediaPath($media->id);
                if (file_exists($mediaFullPath)) {
                    $item['media_path'] = $mediaRelativePath;
                }

                // Store the media in the database
                $this->insertMedia($item, 'inpn');

                // For the URL, we use a specific Occtax URL
                $occtaxMediaUrl = jUrl::getFull(
                    'taxon~media:getMedia',
                    array(
                        'cd_ref' => $this->cd_ref,
                        'id' => $media->id,
                        'source' => 'inpn'
                    )
                );

                $item['url'] = $occtaxMediaUrl;
                $medias[] = $item;
            }
        }

        return $medias;
    }

    /**
     * Compute the media path
     *
     * @return string relative media path
     */
    private function computeRelativeMediaPath($mediaId)
    {
        // Base directory
        $mediaFtpDirectory = 'media/upload/taxon/inpn/' . $this->cd_ref;

        // Lizmap media path
        // File name
        $fileName = sprintf(
            '%s_%s.jpg',
            $this->cd_ref,
            $mediaId
        );
        $mediaRelativePath = $mediaFtpDirectory . '/' . $fileName;

        // Full path
        $lizmapProject = lizmap::getProject($this->repository . '~' . $this->project);
        $repositoryPath = $lizmapProject->getRepository()->getPath();
        $mediaFullDirectory = $repositoryPath . '/' . $mediaFtpDirectory;
        $mediaFullPath = $repositoryPath . '/' . $mediaRelativePath;

        return array($mediaFtpDirectory, $mediaRelativePath, $mediaFullDirectory, $mediaFullPath);
    }

    /**
     * Store a media in the FTP folder
     *
     * @param integer $id The media id
     * @param integer $url The media URL
     * @param boolean $override If we need to override the existing image file
     *
     * @return string $url New URL
     */
    private function storeInpnMedia($id, $url, $override = False)
    {
        // API media URL
        $apiUrl = $url;

        // Get relative media path
        list($mediaFtpDirectory, $mediaRelativePath, $mediaFullDirectory, $mediaFullPath) = $this->computeRelativeMediaPath($id);

        // Create the target directory
        try {
            \jFile::createDir($mediaFullDirectory);
        } catch (Exception $e) {
            \jLog::log($e->getMessage());
            return $apiUrl;
        }
        if (!is_dir($mediaFullDirectory)) {
            \jLog::log('Error while creating ' . $mediaFullDirectory);
            return $apiUrl;
        }

        // Lizmap media URL
        $mediaCacheUrl = jUrl::getFull(
            'view~media:getMedia',
            array(
                'repository' => $this->repository,
                'project' => $this->project,
                'path' => $mediaRelativePath
            )
        );

        // Check if the file exists
        if (file_exists($mediaFullPath) && !$override) {
            $this->updateMediaPath($id, $mediaRelativePath);
            return $mediaCacheUrl;
        }

        // Download from the API with a timeout
        $context = stream_context_create(
            array(
                'http' => array(
                    'timeout' => 5
                )
            )
        );
        try {
            file_put_contents(
                $mediaFullPath,
                fopen($apiUrl, 'r', false, $context)
            );
        } catch (Exception $e) {
            \jLog::log($e->getMessage());
            return $apiUrl;
        }

        // If the file still does not exist, return the original API URL
        if (!file_exists($mediaFullPath)) {
            return $apiUrl;
        }

        $this->updateMediaPath($id, $mediaRelativePath);

        return $mediaCacheUrl;
    }

    /**
     * Update the table taxon.medias
     * and set the media_path field
     *
     * @param integer $id Id of the media in the INPN API
     * @param string $mediaRelativePath Path of the media to edit
     *
     */
    private function updateMediaPath($id, $mediaRelativePath) {
        // We can update the database line for this media file
        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $sql = "
            UPDATE taxon.medias
            SET media_path = $1
            WHERE cd_ref = $2
            AND source = $3
            AND id_origine = $4
        ";
        $resultset = $cnx->prepare($sql);
        $params = array(
            $mediaRelativePath,
            $this->cd_ref,
            'inpn',
            $id
        );
        $resultset->execute($params);
    }
}
