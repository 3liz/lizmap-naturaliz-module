<div>
    <!-- Gestion du profile -->
    <div id="mascarine_personne_user" class="menu-content">
      <form id="form_mascarine_personne_user" method="post" action="{jurl 'mascarine~personne:modify'}">
          <input type="submit" class="btn" value="Gérer mon profil"></input>
      </form>
    </div>
    <!-- Gestion des géométries -->
    <div id="mascarine_observation_add">
        <h3>
          <span class="title">
            <span class="icon"></span>&nbsp;<span class="text">Parcours</span>
            <span class="pull-right">
                <button type="button" class="btn btn-mini zoom" style="background:#E6E6E6; padding:2px;"
                        title="{@mascarine~search.result.zoom.title@}">
                    <i class="icon-search"></i>
                </button>
            </span>
          </span>
        </h3>
        <div id="div_form_mascarine_observation_geometry" class="menu-content" style="min-width:320px;">
            <div id="obs-spatial-draw-buttons" class="controls">
                <div class="btn-group" data-toggle="buttons-radio">
                    <button type="button" id="obs-spatial-draw-point" data-value="drawPoint"
                        class="btn point draw" title ="Ajouter un point" alt="Cliquez sur la carte pour ajouter le point">
                    </button>
                    <button type="button" id="obs-spatial-draw-write" data-value="writePoint"
                        class="btn write" title ="Saisie des coordonnées" alt="Entrez les coordonnées UTM 20 Nord dans les champs textes ci-dessous">
                    </button>
                    <button type="button" id="obs-spatial-draw-line" data-value="drawLine"
                        class="btn line draw" title ="Tracer une ligne" alt="Tracez une ligne en cliquant les points sur la carte. Terminez la ligne en double-cliquant le dernier sommet">
                    </button>
                    <button type="button" id="obs-spatial-draw-polygon" data-value="drawPolygon"
                        class="btn polygon draw" title="Tracer un polygone" alt="Tracez un polygone en cliquant pour chaque sommet du polygone. Double-cliquez pour terminer le polygone">
                    </button>   
                    <button type="button" id="obs-spatial-draw-point" data-value="drawCancel"
                        class="btn cancel confirm" title="Effacer" alt="Souhaitez-vous effacez toutes les géométries ?">
                    </button>
                </div>
                <div class="btn-group" data-toggle="buttons-radio">
                    <button data-value="gpx" data-query='object'
                        class="btn gpx" type="button" title="Importer un fichier GPS" alt="">
                    </button>
                </div>
                <div class="btn-group" data-toggle="buttons-radio">
                    <button type="button" id="obs-spatial-manage-delete" data-value="deleteGeometry"
                        class="btn delete manage confirm disabled" title="Supprimer la géométrie sélectionnée" alt="Souhaitez-vous supprimer la géométrie sélectionnée ?">
                    </button>
                    <button type="button" id="obs-spatial-manage-intersect" data-value="intersectGeometry"
                        class="btn intersect manage confirm disabled" title="Découper la géométrie sélectionnée" alt="Souhaitez-vous découper la géométrie sélectionnée selon les communes et les mailles ?">
                    </button>
                    <button type="button" id="obs-spatial-manage-split" data-value="splitGeometry"
                        class="btn split manage disabled" title="Découper manuellement les lignes" alt="Tracer une ligne de découpe en cliquant sur la carte. Terminer en double-cliquant">
                    </button>
                    <button type="button" id="obs-spatial-manage-add" data-value="addGeometry"
                        class="btn add manage disabled" title="Ajouter à la liste des parcours" alt="Ajouter la géométrie à la liste des parcours">
                    </button>
                </div>
            </div>
            <div id="div_form_mascarine_draw_write" style="display:none; margin-top:10px;">
                {formfull $formWrite, '#', array(), 'htmlbootstrap'}
            </div>
            <!-- forms -->
            <div style="display:none;">
              <form id="form_mascarine_service_saveTemp" method="post" action="{jurl 'mascarine~service:saveTemp'}">
              </form>
              <div id="div_form_mascarine_service_upload_gpx" style="display:none;">
                {formfull $formUpload, 'mascarine~service:uploadGPX', array(), 'htmlbootstrap'}
              </div>
              <form id="form_mascarine_service_intersectGeometry" method="post" action="{jurl 'mascarine~service:intersectGeometry'}">
              </form>
              <form id="form_mascarine_service_testGeometry" method="post" action="{jurl 'mascarine~service:testGeometry'}">
              </form>
              <form id="form_mascarine_add_obs" method="post" action="{jurl 'mascarine~add_obs:index'}">
                <input type="hidden" name="code_commune"></input>
                <input type="hidden" name="code_maille"></input>
                <input type="hidden" name="geo_wkt"></input>
                <input type="hidden" name="ol_feat_id"></input>
              </form>
              <form id="form_mascarine_organisme_add" method="post" action="{jurl 'mascarine~organisme:add'}">
              </form>
              <form id="form_mascarine_personne_add" method="post" action="{jurl 'mascarine~personne:add'}">
              </form>
            </div>
        </div>
    </div>
    
    <!-- Tableau des observations non validées -->
    <div id="mascarine_observation_unvalid">
        <h3>
            <span class="title">
                <span class="icon"></span>&nbsp;<span class="text">{@mascarine~observation.table.unvalidate@}</span>
                <span class="pull-right">
                    <button type="button" class="btn btn-mini zoom" style="background:#E6E6E6; padding:2px;"
                            title="{@mascarine~search.result.zoom.title@}">
                        <i class="icon-search"></i>
                    </button>
                </span>
            </span>
        </h3>
        <div id="mascarine_observation_unvalid_div_table" class="menu-content">
              <form id="mascarine_observation_unvalid_form" method="post" action="{jurl 'mascarine~observation:unvalid'}" style="display:none;">
                <input type="hidden" name="limit"></input>
                <input type="hidden" name="offset"></input>
              </form>
              {zone 'taxon~datatable', array('classId'=>'mascarine~unvalidateObservationSearch','tableId'=>'mascarine_observation_unvalid_table')}
        </div>
    </div>
    
    <div id="div_mascarine_observation_forms">
    </div>
    
</div>
