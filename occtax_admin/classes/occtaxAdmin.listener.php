<?php
class occtaxAdminListener extends jEventListener{

  function onmasteradminGetMenuContent ($event) {
      // Create the "lizmap" parent menu item
      $bloc = new masterAdminMenuItem('occtax', 'Occtax', '', 200);

      // Child for the configuration of Mascarine forms
      $bloc->childItems[] = new masterAdminMenuItem(
        'occtax_config',
        'Configuration',
        jUrl::get('occtax_admin~config:index'), 210, 'occtax'
      );

      // Add the bloc
      if( jAcl2::check( 'occtax.admin.config.gerer' ) )
        $event->add($bloc);
  }

}
