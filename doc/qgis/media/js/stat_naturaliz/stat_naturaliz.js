lizMap.events.on({

  uicreated: function(e){
    // Le bouton Home redirige vers naturaliz
    // var newHomeLink = window.location.origin;
    // $('#mapmenu li.home a').attr('href', newHomeLink);
    // $('#mapmenu li.home a').attr('target', '_blank');

    // On masque l'outil de légende
    $('#mapmenu li.switcher.active a').click().hide();

    // On masque le menu (i)
    $('#mapmenu li.metadata').hide();

    // On modifie le menu Données
    $('#mapmenu li.attributeLayers a').attr('data-original-title', 'Chiffres-clés');

    // On masque le permalien
    $('#mapmenu li.permaLink').hide();

    // On masque le mot Options dans la table attributaire
    $('#bottom-dock b:contains("Options")').hide();

    // On enlève le comportement sur hover in et out du bottom dock
    $('#bottom-dock').unbind('mouseenter mouseleave')

    // On change le z-index pour permettre l'affichage des tooltip du menu de gauche
    $('#bottom-dock').css('z-index', '1100');

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

    // Redimensionner les graphiques sur clic d'un onglet
    $('ul#borbonica-stats-tab li').click(function(){
      $('#bottom-dock div.js-plotly-plot').each(function(){
        let self = $(this);
        let id = self.attr('id');
        lizDataviz.resizePlot(id)
      });
    })

  }
});
