<?php
class mascarineAdminListener extends jEventListener{

  function onmasteradminGetMenuContent ($event) {
      // Create the "lizmap" parent menu item
      $bloc = new masterAdminMenuItem('mascarine', 'Mascarine', '', 200);

      // Child for the configuration of Mascarine forms
      $bloc->childItems[] = new masterAdminMenuItem(
        'mascarine_config',
        'Configuration',
        jUrl::get('mascarine_admin~config:index'), 210, 'mascarine'
      );
      $bloc->childItems[] = new masterAdminMenuItem(
        'mascarine_forms',
        'Formulaires',
        jUrl::get('mascarine_admin~forms:index'), 220, 'mascarine'
      );

      // Add the bloc
      if( jAcl2::check( 'mascarine.admin.config.gerer' ) )
        $event->add($bloc);
  }

}
