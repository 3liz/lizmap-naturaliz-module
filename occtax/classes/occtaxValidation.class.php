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

    protected $user_jelix = Null;

    public function __construct ($login=Null) {
        if (!$login) {
            $user_jelix = jAuth::getUserSession();
            if ($user_jelix) {
                $login = $user_jelix->login;
            }
            $this->user_jelix = $user_jelix;
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
            SELECT
            o.cle_obs,
            vo.identifiant_permanent,
            vo.date_ctrl,
            vo.niv_val,
            vo.typ_val,
            vo.ech_val,
            vo.peri_val,
            vo.proc_vers,
            vo.producteur,
            vo.date_contact,
            vo.procedure,
            vo.proc_ref,
            vo.comm_val,
            vo.nom_retenu,
            vp.id AS in_panier
            FROM occtax.observation AS o
            LEFT JOIN occtax.validation_observation AS vo
            USING (identifiant_permanent)
            LEFT JOIN occtax.validation_panier AS vp
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


    public function validateObservationsFromBasket($input_params) {
        // Todo
        // Ajouter un WHERE avec le filtre sur les demandes, pour le champ "validateur" True
        // Get observation from basket
        $keys = array('niv_val', 'producteur', 'date_contact', 'comm_val', 'nom_retenu');
        $params = array(
            $this->login
        );
        foreach ($keys as $key) {
            $params[] = $value;
        }

        //$columns = array();
        //$values = array();
        //$i = 0;
        //$fields = array();
        //foreach ($keys as $key) {
            //$value = $input_params[$i];
            //if (!empty($value)) {
                //$params[] = $value;
                //$fields[] = $key;
            //}
            //$i++;
        //}

// TODO: maj autoamtique de procedure et proc_vers en récupérant la dernière ligne de la table idoine
// Trigger:
// occtax.validation_observation
// - comm_val: essayer de garder le commentaire précédent. ATTENTION, faire un replace du commentaire
// occtax.observation
// Faire aussi directement un update sur occtax.observation.
// Concaténer le nouveau commentaire et l'ancien

// Faire un UPSERT car on n'a pas toujours de ligne dans la table validation_observation
// donc il faut mettre M à typ_val et le protocole

// Permettre de voir le formulaire pour modifier une observation, le
// Formulaire de droite: l'appeler 'Validation du panier"
//-> utiliser une fenêtre modale

        $cnx = jDb::getConnection();
        $sql = " WITH panier AS (";
        $sql.= "    SELECT vp.*, valo.typ_val, valo.comm_val";
        $sql.= "    FROM occtax.validation_panier AS vp";
        $sql.= "    LEFT JOIN occtax.validation_observation AS valo USING (identifiant_permanent)";
        $sql.= "    WHERE True";
        $sql.= "    AND vp.usr_login = $1";
        $sql.= " )";

        $sql.= "INSERT INTO occtax.validation_observation AS vo";
        $sql.= "(";
        $sql.= "    identifiant_permanent,";
        $sql.= "    date_ctrl,";
        $sql.= "    typ_val,";
        $sql.= "    ech_val,";
        $sql.= "    peri_val,";
        // données du form
        $sql.= "    niv_val,";
        $sql.= "    producteur,";
        $sql.= "    date_contact,";
        $sql.= "    comm_val,";
        $sql.= "    nom_retenu,";
        // Validateur
        $sql.= "    validateur,";
        // procédure
        $sql.= "    \"procedure\",";
        $sql.= "    proc_vers,";
        $sql.= "    proc_ref";
        $sql.= ")";

        $sql.= "SELECT";
        $sql.= "    p.identifiant_permanent,";
        $sql.= "    now(),";
        $sql.= "    'M',";
        $sql.= "    '2',";
        $sql.= "    '1',";

        // Données du formulaire
        $sql.= "    $2,";
        $sql.= "    nullif(trim($3), ''),";
        $sql.= "    nullif(trim($4), ''),";
        $sql.= "    nullif(trim(trim(concat(replace(p.comm_val, $5, ''), ' - ', trim($5)), ' - ')), ''),";
        $sql.= "    nullif(trim($6), ''),";

        // on va chercher le id_personne du validateur
        $sql.= "    (";
        $sql.= "        SELECT id_personne";
        $sql.= "        FROM occtax.personne";
        $sql.= "        WHERE mail = " . $cnx->quote($this->user_jelix->email);
        $sql.= "    ),";

        // On utilise les valeurs de la table procedure
        $sql.= "    p.\"procedure\",";
        $sql.= "    p.proc_vers,";
        $sql.= "    p.proc_ref";

        $sql.= " FROM panier p,";
        $sql.= " (";
        $sql.= "     SELECT \"procedure\", proc_vers, proc_ref";
        $sql.= "     FROM occtax.validation_procedure, regexp_split_to_array(trim(proc_vers),  ''\.'')  AS a";
        $sql.= "     ORDER BY concat(lpad(a[1], 3, ''0''), lpad(a[2], 3, ''0''), lpad(a[3], 3, ''0'')) DESC";
        $sql.= "     LIMIT 1";
        $sql.= " ) AS p";
        $sql.= " WHERE True";

        // Si conflict, cad si une ligne existe déjà on modifie les données
        $sql.= " ON CONFLICT ON CONSTRAINT validation_observation_identifiant_permanent_ech_val_unique";
        $sql.= " DO ";
        $sql.= " UPDATE occtax.validation_observation AS vo";
        $sql.= " SET (";
        $sql.= "    date_ctrl,";
        $sql.= "    typ_val,";
        $sql.= "    ech_val,";
        $sql.= "    peri_val,";
        // données du form
        $sql.= "    niv_val,";
        $sql.= "    producteur,";
        $sql.= "    date_contact,";
        $sql.= "    comm_val,";
        $sql.= "    nom_retenu,";
        // Validateur
        $sql.= "    validateur,";
        // procédure
        $sql.= "    \"procedure\",";
        $sql.= "    proc_vers,";
        $sql.= "    proc_ref";
        $sql.= " ) = (";
        $sql.= "    now(), ";
        $sql.= "    EXCLUDED.niv_val,";
        $sql.= " )";

        $numbers = array();
        foreach (range(0, count($fields) - 1) as $number) {
            $numbers[] = '$' . (string)($number+2);
        }
        $sql.= implode(', ', $numbers);
        $sql.= ")";


        $data = $this->query($sql, $params);
        return $data;
    }

}
