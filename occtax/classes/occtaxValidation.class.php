<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('occtax~occtaxSearchObservation');

class occtaxValidation {

    protected $login = Null;

    protected $user_jelix = Null;

    protected $demande_filter = '';

    public function __construct ($login=Null) {
        $user_jelix = jAuth::getUserSession();
        $this->user_jelix = $user_jelix;
        if (!$login) {
            if ($user_jelix) {
                $login = $user_jelix->login;
            }
        }
        $this->login = $login;

        $this->demande_filter = $this->getDemandeFilter();

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
        $uuid_regexp = '/^([0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12})$/i';
        if (!is_string($uuid) || (preg_match($uuid_regexp, $uuid) !== 1)) {
            return false;
        }

        return true;
    }


    /**
     * Check if the authenticated user has a line corresponding
     * in the occtax.personne table
     * We check the emails equality
     *
     * @param string $uuid The string to check
     *
     * @return bool
     */
    public function authenticatedUserIsInPersonTable() {
        $params = array(
            $this->login
        );

        $sql = "";
        $sql.= " SELECT p.id_personne";
        $sql.= " FROM occtax.personne AS p";
        $sql.= " JOIN gestion.demande AS d ON p.id_personne = d.id_validateur";
        $sql.= " WHERE d.usr_login = $1::text";
        $sql.= " AND d.type_demande = 'VA'";
        $sql.= " ";

        $data = $this->query($sql, $params);
        if ($data && is_array($data) && count($data) == 1) {
            return True;
        }
        return False;

    }

    /**
     * Get the filter from demande
     *
     * @return string
     */
    protected function getDemandeFilter() {
        $sql = '';
        if( $this->login  ){
            $eventParams = array('login' => $this->login);
            $filters = jEvent::notify('getOcctaxFilters', $eventParams)->getResponse();
            foreach($filters as $filter){
                // On récupère le filtre
                $sql.= $filter;
            }
        }
        //jLog::log($sql);
        return $sql;
    }

    protected function query($sql, $params) {
        $cnx = jDb::getConnection();
//jLog::log($sql);
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
        $sql = "SELECT count(*) AS nb FROM occtax.validation_panier WHERE usr_login = $1::text";
        $params = array(
            $this->login,
        );
        $data = $this->query($sql, $params);
        return $data;

    }

    public function getObservationValidity($id_obs=-1, $id_column='cle_obs') {
        // validate parameters
        if (!in_array($id_column, array('cle_obs', 'identifiant_permanent'))) {
            $id_obs = -1;
            $id_column = 'cle_obs';
        }
        if ($id_column == 'identifiant_permanent' && !$this->isValidUuid($id_obs)) {
            $id_obs = -1;
            $id_column = 'cle_obs';
        }
        // Get data from the basket
        $sql = "
            SELECT
            o.cle_obs,
            o.identifiant_permanent,
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
            vp.id AS in_panier,
            (
                SELECT concat(
                    'Niveau @', vop.niv_val, '@ attribué le ',
                    vop.date_ctrl,
                    ' par ',  identite,
                    ' (' || vop.comm_val || ')'
                ) FROM occtax.validation_observation vop
                JOIN occtax.personne p
                    ON p.id_personne = vop.validateur
                WHERE True
                AND vop.identifiant_permanent = o.identifiant_permanent
                AND vop.ech_val = '1'
                LIMIT 1
            ) AS validation_producteur,
            (
                SELECT concat(
                    'Niveau @', von.niv_val, '@ attribué le ',
                    von.date_ctrl,
                    ' par ',  identite,
                    ' (' || von.comm_val || ')'
                ) FROM occtax.validation_observation von
                JOIN occtax.personne p
                    ON p.id_personne = von.validateur
                WHERE True
                AND von.identifiant_permanent = o.identifiant_permanent
                AND von.ech_val = '3'
                LIMIT 1
            ) AS validation_nationale
            FROM occtax.vm_observation AS o
            LEFT JOIN occtax.validation_observation AS vo
                ON o.identifiant_permanent = vo.identifiant_permanent
                AND vo.ech_val = '2'
            LEFT JOIN occtax.validation_panier AS vp
                ON o.identifiant_permanent = vp.identifiant_permanent
            WHERE True
        ";
        if ($id_column == 'cle_obs') {
            $sql.= " AND cle_obs = $1";
        } else {
            $sql.= " AND o.identifiant_permanent = $1";
        }

        $sql.= $this->demande_filter;
        $sql.= "
            LIMIT 1
        ";
        $params = array(
            $id_obs,
        );
        $data = $this->query($sql, $params);

        return $data;

    }

    public function emptyValidationBasket() {
        // Empty the basket
        $cnx = jDb::getConnection();
        $sql = "DELETE FROM occtax.validation_panier WHERE usr_login = $1::text";
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
        $sql.= " VALUES ($1::text, $2)";
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
        $sql.= " AND usr_login = $1::text";
        $sql.= " AND identifiant_permanent = $2";
        $sql.= " RETURNING id";
        $params = array(
            $this->login,
            $id,
        );
        $data = $this->query($sql, $params);
        return $data;
    }


    public function validateObservations($input_params) {
        // Todo
        // Ajouter un WHERE avec le filtre sur les demandes, pour le champ "validateur" True
        // Get observation from basket
        $user_params = array(
            $this->login
        );

        // Check if identifiant_permanent is given
        $identifiant_permanent = $input_params[5];
        if (!$this->isValidUuid($identifiant_permanent)) {
            // Get rid of useless identifiant_permanent in params
            array_pop($input_params);
        }
        $params = array_merge($user_params, $input_params);

        // Build SQL
        // We use an UPSERT
        $cnx = jDb::getConnection();
        // Uid est donné: on a un identifiant permanent: on valide cette observation
        if (!empty($identifiant_permanent) && $this->isValidUuid($identifiant_permanent)) {
            $sql = " WITH panier AS (";
            $sql.= "    SELECT o.cle_obs, o.identifiant_permanent, $1::text";
            $sql.= "    FROM occtax.vm_observation AS o";
            $sql.= "    WHERE True";
            $sql.= "    AND o.identifiant_permanent = $7";
            // Chercher dans les demandes
            $sql.= $this->demande_filter;
            $sql.= " ) ";
        }
        // Observations du panier
        else {
            $sql = " WITH panier AS (";
            $sql.= "    SELECT vp.*, valo.typ_val, valo.comm_val";
            $sql.= "    FROM occtax.validation_panier AS vp";
            $sql.= "    JOIN occtax.vm_observation AS o USING (identifiant_permanent)";
            $sql.= "    LEFT JOIN occtax.validation_observation AS valo USING (identifiant_permanent)";
            $sql.= "    WHERE True";
            $sql.= "    AND valo.ech_val = '2'";
            $sql.= "    AND vp.usr_login = $1::text";
            // Chercher dans les demandes
            $sql.= $this->demande_filter;
            $sql.= " ) ";

        }

        $sql.= " INSERT INTO occtax.validation_observation AS vo";
        $sql.= " (";
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
        $sql.= " )";

        $sql.= " SELECT";
        $sql.= "    pa.identifiant_permanent,";
        $sql.= "    now(),";
        $sql.= "    'M',";
        $sql.= "    '2',";
        $sql.= "    '1',";

        // Données du formulaire
        $sql.= "    $2,"; // niv_val
        $sql.= "    nullif(trim($3), ''),"; // producteur
        $sql.= "    nullif(trim($4), '')::date,"; // date_contact
        // Validation du 21/08/2021 (Jean DUPONT) : commentaire ajouté
        $sql.= "    'Validation du ' || now()::date || ' : ' || nullif(trim($5), ''),"; // comm_val

        $sql.= "    nullif(trim($6), ''),"; // nom_retenu

        // on va chercher le id_personne du validateur: c'est le id_validateur de gestion.demande
        $sql.= "    (";
        $sql.= "        SELECT id_validateur";
        $sql.= "        FROM gestion.demande";
        $sql.= "        WHERE usr_login = $1::text";
        $sql.= "        AND type_demande = 'VA'";
        $sql.= "        LIMIT 1";
        $sql.= "    ),";

        // On utilise les valeurs de la table procedure
        $sql.= "    pro.\"procedure\",";
        $sql.= "    pro.proc_vers,";
        $sql.= "    pro.proc_ref";

        $sql.= " FROM panier pa,";

        // Sous-requête pour récupérer les informations de la dernières version de la procédure de validation
        $sql.= " (";
        $sql.= "     SELECT \"procedure\", proc_vers, proc_ref";
        $sql.= "     FROM occtax.validation_procedure, regexp_split_to_array(trim(proc_vers),  '\.')  AS a";
        $sql.= "     ORDER BY concat(lpad(a[1], 3, '0'), lpad(a[2], 3, '0'), lpad(a[3], 3, '0')) DESC";
        $sql.= "     LIMIT 1";
        $sql.= " ) AS pro";
        $sql.= " WHERE True";

        // Si conflict, cad si une ligne existe déjà on modifie les données
        $sql.= " ON CONFLICT ON CONSTRAINT validation_observation_identifiant_permanent_ech_val_unique";
        $sql.= " DO ";
        $sql.= " UPDATE";
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
        $sql.= "    CASE
                        WHEN vo.typ_val IN ('A', 'C') THEN 'C'
                        ELSE 'M'
                    END,";
        $sql.= "    '2',";
        $sql.= "    '1',";
        // données du form
        $sql.= "    EXCLUDED.niv_val,";
        $sql.= "    EXCLUDED.producteur,";
        $sql.= "    EXCLUDED.date_contact,";
        // Pour comm_val, on a affiché dans le formulaire un champ vide
        // Pour ne pas risquer de supprimer les commentaires précédents
        // On préfère toujours concaténer le commentaire ajouté au précédent
        // On essaye néanmoins de ne pas avoir de texte en double à cause de la concaténation
        $sql.= "    trim(trim(
                        concat(
                                replace(
                                    vo.comm_val,
                                    EXCLUDED.comm_val,
                                    ''
                                ) || ' - ',
                                EXCLUDED.comm_val
                        ),
                        '-'
                    )),
        ";
        $sql.= "    EXCLUDED.nom_retenu,";
        $sql.= "    EXCLUDED.validateur,";
        $sql.= "    EXCLUDED.\"procedure\",";
        $sql.= "    EXCLUDED.proc_vers,";
        $sql.= "    EXCLUDED.proc_ref";
        $sql.= " )";
        $sql.= "";

        $data = $this->query($sql, $params);
        return $data;
    }

    public function addSearchResultToBasket($token) {
        // TODO: Check the observation can be seen by the authenticated user !
        // Add observation to the basket
        $cnx = jDb::getConnection();

        // Get observation SQL from token
        $occtaxSearch = new occtaxSearchObservation( $token, null, null, $this->login );
        $sql_search = $occtaxSearch->getSql();
        // NB : no need to add demande_filter here since it is already done
        // in the occtaxSearchObservationsetWhereClause method

        $sql = " WITH s AS (";
        $sql.= $sql_search;
        $sql.= " )";
        $sql.= " INSERT INTO occtax.validation_panier (usr_login, identifiant_permanent)";
        $sql.= " SELECT $1::text, s.identifiant_permanent";
        $sql.= " FROM s";
        $sql.= " WHERE True";
        $sql.= " ON CONFLICT ON CONSTRAINT validation_panier_usr_login_identifiant_permanent_key";
        $sql.= " DO NOTHING";
        $sql.= " RETURNING id";
        $params = array(
            $this->login,
        );
        $data = $this->query($sql, $params);
        // We just get the count to avoid passing all ids to the browser
        $data = array(array('count'=>count($data)));
        return $data;
    }

}
