<div style="height:100%;overflow:auto;">
    <h3>
        <span class="title">
            <span class="icon"></span>&nbsp;
            <span class="text">{@import.dock.title@}</span>
        </span>
    </h3>
    <div class="menu-content">
        <div id="occtax_import_tab_div" class="container" style="width:100%;">
            <h4>Tester la conformité de données d'observation selon le standard Occurences de Taxon</h4>

            <p>Veuillez consulter au préalable les ressources suivantes</p>
            <ul>
                <li>le <a href="https://standards-sinp.mnhn.fr/category/standards/occurrences-de-taxons/" target="_blank">Standard Occurrences de Taxon</a></li>
                <li>un <a href="{jurl 'occtax~import:getTemplateCsv'}" target="_blank">Exemple de fichier CSV conforme</a></li>
            </ul>
            <ul class="nav nav-tabs">
                <li class="active"><a href="#import_formulaire" data-toggle="tab">Formulaire</a></li>
                <li class=""><a href="#import_conformite" data-toggle="tab">Conformité</a></li>
                <li class=""><a href="#import_resultat" data-toggle="tab">Résultat</a></li>
            </ul>
            <div class="tab-content">
                <div id="import_formulaire" class="tab-pane active">
                    <div class="occtax_import_form">
                        {formfull $form, 'occtax~import:check', array(), 'htmlbootstrap'}
                    </div>
                </div>
                <div id="import_conformite" class="tab-pane ">

                    <span id="import_message" style="font-weight: bold;font-size: 1.1em;"></span>

                    <div>
                        <h4>Valeurs vides</h4>
                        <table id="import_conformite_not_null" class="table table-condensed table-striped table-bordered">
                            <tr>
                                <th>Libellé</th>
                                <th>Nombre de lignes en erreur</th>
                                <th>Identifiants concernés</th>
                            </tr>
                            <tr>
                                <td>-</td>
                                <td>-</td>
                                <td>-</td>
                            </tr>
                        </table>
                    </div>

                    <div>
                        <h4>Format des données</h4>
                        <table id="import_conformite_format" class="table table-condensed table-striped table-bordered">
                            <tr>
                                <th>Libellé</th>
                                <th>Nombre de lignes en erreur</th>
                                <th>Identifiants concernés</th>
                            </tr>
                            <tr>
                                <td>-</td>
                                <td>-</td>
                                <td>-</td>
                            </tr>
                        </table>
                    </div>

                    <div>
                        <h4>Conformités aux règles du standard</h4>
                        <table id="import_conformite_conforme" class="table table-condensed table-striped table-bordered">
                            <tr>
                                <th>Libellé</th>
                                <th>Nombre de lignes en erreur</th>
                                <th>Identifiants concernés</th>
                            </tr>
                            <tr>
                                <td>-</td>
                                <td>-</td>
                                <td>-</td>
                            </tr>
                        </table>
                    </div>
                </div>

                <div id="import_resultat" class="tab-pane ">

                    <span id="import_message_resultat" style="font-weight: bold;font-size: 1.1em;"></span>

                    <div>
                        <h4>Nombre d'éléments importés</h4>
                        <table id="import_resultat_table" class="table table-condensed table-striped table-bordered">
                            <tr>
                                <th>Observations</th>
                                <th>Organismes</th>
                                <th>Personnes</th>
                                <th>Liens observation/observateurs</th>
                                <th>Liens observation/déterminateurs</th>
                            </tr>
                            <tr>
                                <td id="import_resultat_observations">-</td>
                                <td id="import_resultat_organismes">-</td>
                                <td id="import_resultat_personnes">-</td>
                                <td id="import_resultat_observateurs">-</td>
                                <td id="import_resultat_determinateurs">-</td>
                            </tr>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
