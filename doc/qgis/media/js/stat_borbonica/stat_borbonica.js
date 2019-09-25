lizMap.events.on({

  uicreated: function(e){
    // Le bouton Home redirige vers borbonica
    var newHomeLink = window.location.origin;
    $('#mapmenu li.home a').attr('href', newHomeLink);
    $('#mapmenu li.home a').attr('target', '_blank');

    // On masque l'outil de légende
    $('#mapmenu li.switcher.active a').click().hide();

    // On masque le menu (i)
    $('#mapmenu li.metadata').hide();

    // On masque le permalien
    $('#mapmenu li.permaLink').hide();

    // On masque le mot Options dans la table attributaire
    $('#bottom-dock b:contains("Options")').hide();

    // On enlève le comportement sur hover in et out du bottom dock
    $('#bottom-dock').unbind('mouseenter mouseleave')

    // On bouge automatiquement les panneaux sur ouverture d'un dock
    lizMap.events.on({
      dockopened: function(){
        $('#bottom-dock').trigger('mouseenter');
      },
      dockclosed: function(){
        $('#bottom-dock').trigger('mouseenter');
      }
    })

    // On ouvre automatiquement le panneau des stats
    $('#mapmenu li.dataviz:not(.active) a').click();
    $('button.btn-bottomdock-size').click();

    // On supprime le bloc de boutons du bas
    $('#bottom-dock-window-buttons').remove();
  }
});

