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
     * Query the database with SQL text and parameters
     *
     * @param string $sql SQL text to run
     * @param array $params Array of the parameters values
     *
     * @return The resulted data
     */
    private function query($sql, $params)
    {
        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $cnx->beginTransaction();
        $data = array();
        try {
            $resultset = $cnx->prepare($sql);
            $resultset->execute($params);
            $data = $resultset->fetchAll();
            $cnx->commit();
        } catch (Exception $e) {
            $cnx->rollback();
            $data = null;
            \jLog::log($e->getMessage());
        }

        return $data;
    }

    /**
     * Get history items from cache.
     * Only for authenticated users.
     *
     */
    public function getSearchHistory()
    {
        $rep = $this->getResponse('json');
        $data = array();
        $history = null;
        $rep->data = $data;

        // Get user login
        $user = jAuth::getUserSession();
        if (!$user) {
            return $rep;
        }

        // Get the history from database
        $login = $user->login;
        $sql = 'SELECT history::json';
        $sql .= ' FROM occtax.historique_recherche';
        $sql .= ' WHERE usr_login = $1';
        $sql .= ' LIMIT 1';
        $sql .= ' ';
        $params = array($login);
        $result = $this->query($sql, $params);
        if ($result) {
            foreach ($result as $item) {
                $history = $item->history;
            }
        }
        if ($history) {
            $data = json_decode($history);
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
        $rep->data = $data;

        // Get user login
        $login = null;
        $user = jAuth::getUserSession();
        if (!$user) {
            return $rep;
        }

        // Get the JSON new history
        $json_string = $this->param('content', '[]');
        try {
            $json = json_decode($json_string, true);
        } catch (Exception $e) {
            $json = array();
        }

        // Set the history to the cache
        $login = $user->login;
        $sql = 'INSERT INTO occtax.historique_recherche';
        $sql .= ' (usr_login, "history") VALUES (';
        $sql .= ' $1, $2::jsonb';
        $sql .= ') ';
        $sql .= ' ON CONFLICT (usr_login) DO UPDATE';
        $sql .= ' SET history = EXCLUDED.history';
        $params = array($login, json_encode($json));
        $result = $this->query($sql, $params);
        if (!$result) {
            $data['status'] = 'error';
        }

        $rep->data = $data;

        return $rep;
    }
}
