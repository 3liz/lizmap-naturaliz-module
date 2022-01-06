<div style="height:100%;overflow:auto;">
    <h3>
        <span class="title">
            <span class="icon-download"></span>&nbsp;
            <span class="text">{@import.dock.title@}</span>
        </span>
    </h3>
    <div class="menu-content">
        <div id="occtax_import_tab_div" class="container" style="width:100%;">
            <b>Tester la conformité puis importer des données d'observation selon le standard Occurences de Taxon</b>
            <ul class="nav nav-tabs">
                <li class="active"><a href="#import_formulaire" data-toggle="tab">Formulaire</a></li>
                <li class=""><a href="#import_conformite" data-toggle="tab">Conformité</a></li>
            </ul>
            <div class="tab-content">
                <div id="import_formulaire" class="tab-pane active">
                    <div class="occtax_import_form">
                        {formfull $form, 'occtax~import:check', array(), 'htmlbootstrap'}
                    </div>
                </div>
                <div id="import_conformite" class="tab-pane ">

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
            </div>
        </div>
    </div>
</div>
