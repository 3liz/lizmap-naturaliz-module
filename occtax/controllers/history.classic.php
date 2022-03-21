<?php

/**
 * @package   lizmap
 * @subpackage occtax
 * @author    Michaël Douchin
 * @copyright 2014 3liz
 * @link      http://3liz.com
 * @license    All rights reserved
 */

class historyCtrl extends jController
{

    /**
     * Get history items from cache.
     * Only for authenticated users.
     *
     */
    public function getSearchHistory()
    {
        $rep = $this->getResponse('json');
        $data = array();

        // Get user login
        $user = jAuth::getUserSession();
        if ($user) {
            // Get the history from cache
            $login = $user->login;
            $key = 'naturaliz_history_' . $login;
            $profile = 'naturaliz_file_cache';
            $history = jCache::get($key, $profile);

            if ($history) {
                $data = json_decode($history);
            }
        }

        $rep->data = $data;

        return $rep;
    }

    /**
     * Save the history items to the cache.
     * Only for authenticated users.
     *
     */
    public function saveSearchHistory()
    {
        $rep = $this->getResponse('json');
        $data = array(
            'status' => 'success',
            'data' => array()
        );

        // Get user login
        $login = null;
        $user = jAuth::getUserSession();
        if ($user) {
            // Get the JSON new history
            $json_string = $this->param('content', '[]');
            try {
                $json = json_decode($json_string, true);
            } catch (Exception $e) {
                $json = array();
            }

            // Set the history to the cache
            $login = $user->login;
            $key = 'naturaliz_history_' . $login;
            $value = json_encode($json);
            $profile = 'naturaliz_file_cache';
            $ttl = 0;
            jCache::set($key, $value, $ttl, $profile);
        }

        $rep->data = $data;

        return $rep;
    }
}
