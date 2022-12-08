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
     * Read the media information downloaded from
     * the external server and return the formated object
     *
     * @param string $data JSON information data
     *
     * @return array $media The formated media
     */
    private function parseMediaInformation($json)
    {
        $mediaData = array(
            'cd_ref' => $this->cd_ref,
            'source' => $this->source,
            'medias' => array()
        );

        // Parse the JSON content
        $data = json_decode($json);
        if (!$data) {
            return $this->response(
                'error',
                'Impossible de parser le JSON du media',
                $media
            );
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
                    'cd_ref' => $this->cd_ref,
                    'id' => $media->id,
                    'copyright' => $media->copyright,
                    'title' => $media->title,
                    'licence' => $media->licence,
                );

                // Store the URL in cache
                $token = md5('inpn_image_' . $this->cd_ref . '@'. $media->id);
                $data = array(
                    'id' => $media->id,
                    'url' => $media->_links->thumbnailFile->href
                );
                jCache::set($token, json_encode($data), 3600);

                // For the URL, we use a specific Occtax URL
                $occtaxMediaUrl = jUrl::getFull(
                    'taxon~media:getMedia',
                    array(
                        'cd_ref' => $this->cd_ref,
                        'token' => $token,
                    )
                );
                $item['url'] = $occtaxMediaUrl;

                // Download the image in cache if asked
                $medias[] = $item;
            }
        }
        $mediaData['medias'] = $medias;

        return $this->response(
            'success',
            null,
            $mediaData
        );
    }

    /**
     * Get a media from the external API
     * or the cache if it is present
     *
     */
    public function getMediaUrl($key) {

        // Get api URL from the cache
        $mediaCache = jCache::get($key);
        if (!$mediaCache) return null;

        // Decode media information
        $media = json_decode($mediaCache);
        if (!$media) return null;
        if (!property_exists($media, 'url')) return null;
        if (!property_exists($media, 'id') || !is_int($media->id)) return null;

        // Check if URL is the INPN API URL
        $id = $media->id;
        $url = $media->url;
        if (!substr($url, 0, strlen($this->mediaDownloadUrl)) === $this->mediaDownloadUrl) {
            return null;
        }

        // Store and send back the media
        $url = $this->storeMedia($id, $url);

        return $url;
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
    private function storeMedia($id, $url, $override = False)
    {
        // API media URL
        $apiUrl = $url;

        // File name
        $fileName = sprintf(
            '%s_%s.jpg',
            $this->cd_ref,
            $id
        );

        // Base directory
        $mediaFtpDirectory = 'media/upload/taxon/inpn/' . $this->cd_ref;

        // Lizmap media path
        $mediaRelativePath = $mediaFtpDirectory . '/' . $fileName;

        // Full path
        $lizmapProject = lizmap::getProject($this->repository . '~' . $this->project);
        $repositoryPath = $lizmapProject->getRepository()->getPath();
        $mediaFullDirectory = $repositoryPath . '/' . $mediaFtpDirectory;
        $mediaFullPath = $repositoryPath . '/' . $mediaRelativePath;

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
            return $mediaCacheUrl;
        }

        // Download from the API
        $context = stream_context_create(
            array(
                'http' => array(
                    'timeout' => 30.0
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
        if (!file_exists($mediaFullPath)) {
            return $apiUrl;
        }

        return $mediaCacheUrl;
    }

    /**
     * Download the information about the media
     * and parse the data to a pivot format
     *
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
        $url = $this->ressourceUrl;
        list($content, $mime, $code) = \Lizmap\Request\Proxy::getRemoteData($url, array(
            'method' => 'get',
            'referer' => jUrl::getFull('view~default:index'),
        ));

        // Detect if the request has failed
        if ($code != 200) {
            return $this->response(
                'error',
                'Impossible de télécharger le media. Code erreur: ' . $code,
                null
            );
        }

        // Parse the data
        $parsedMedia = $this->parseMediaInformation($content);

        return $parsedMedia;
    }


    /**
     *
     */
}
