<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class occtaxValidation {

    protected $login = Null;

    public function __construct ($login=Null) {
        if (!$login) {
            $user_jelix = jAuth::getUserSession();
            if ($user_jelix) {
                $login = $user_jelix->login;
            }
        }
        $this->login = $login;
    }

    /**
     * Check if a given string is a valid UUID.
     *
     * @param string $uuid The string to check
     *
     * @return bool
     */
    public function isValidUuid($uuid)
    {
        if (!is_string($uuid) || (preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/', $uuid) !== 1)) {
            return false;
        }

        return true;
    }

    protected function query($sql, $params) {
        $cnx = jDb::getConnection();
        try {
            $stmt = $cnx->prepare($sql);
            $stmt->execute($params);
        } catch(Exception $e) {
            return null;
        }
        return $stmt->fetchAll();
    }

    public function getValidationBasket() {
        // Get data from the basket
        $sql = "SELECT * FROM occtax.validation_panier WHERE usr_login = $1";
        $params = array(
            $this->login,
        );
        $data = $this->query($sql, $params);
        return $data;

    }

    public function getObservationValidity($cle_obs) {
        // Get data from the basket
        $sql = "
            SELECT o.cle_obs, vo.*
            FROM occtax.observation AS o
            LEFT JOIN occtax.validation_observation AS vo
            USING (identifiant_permanent)
            WHERE cle_obs = $1
            LIMIT 1
        ";
        $params = array(
            $cle_obs,
        );
        $data = $this->query($sql, $params);
        return $data;

    }

    public function emptyValidationBasket() {
        // Empty the basket
        $cnx = jDb::getConnection();
        $sql = "DELETE FROM occtax.validation_panier WHERE usr_login = $1";
        $params = array(
            $this->login,
        );
        $data = $this->query($sql, $params);
        return $data;
    }

    public function addObservationToBasket($id) {
        // TODO: Check the observation can be seen by the authenticated user !
        // Add observation to the basket
        $cnx = jDb::getConnection();
        $sql = " INSERT INTO occtax.validation_panier (usr_login, identifiant_permanent)";
        $sql.= " VALUES ($1, $2)";
        $sql.= " ON CONFLICT ON CONSTRAINT validation_panier_usr_login_identifiant_permanent_key";
        $sql.= " DO NOTHING";
        $sql.= " RETURNING id";
        $params = array(
            $this->login,
            $id,
        );
        $data = $this->query($sql, $params);
        return $data;
    }

    public function removeObservationFromBasket($id) {
        // Get observation from basket
        $cnx = jDb::getConnection();
        $sql = " DELETE FROM occtax.validation_panier";
        $sql.= " WHERE True";
        $sql.= " AND usr_login = $1";
        $sql.= " AND identifiant_permanent = $2";
        $sql.= " RETURNING id";
        $params = array(
            $this->login,
            $id,
        );
        $data = $this->query($sql, $params);
        return $data;
    }


    public function validateObservationsFromBasket($params) {
        // Todo
        // Contrôler les valeurs du formulaire
        // Akouter un WHERE avec le filtre sur les demandes, pour le champ "validateur" True
        // Get observation from basket
        $cnx = jDb::getConnection();
        $sql = " WITH panier AS (";
        $sql.= "    SELECT * FROM occtax.validation_panier";
        $sql.= "    WHERE True";
        $sql.= "    AND usr_login = $1";
        $sql.= " )";
        $sql.= " UPDATE occtax.validation_observation AS vo";
        $sql.= " SET (niv_val, producteur, date_contact, comm_val, nom_retenu) = ";
        $sql.= "($2, $3, $4, $5, $6)";
        $sql.= " FROM panier p";
        $sql.= " WHERE p.identifiant_permanent = vo.identifiant_permanent";
        $sql.= " RETURNING vo.identifiant_permanent";
        $params = array(
            $this->login,
        );
        $data = $this->query($sql, $params);
        return $data;
    }

}
