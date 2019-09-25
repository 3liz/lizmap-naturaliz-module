lizMap.events.on({
    'uicreated':function(evt){
        // Add empty dock
        lizMap.addDock('dataviz', 'Statistiques', 'dock', '', 'icon-signal');

        // Use standard Dataviz menu icon
        $('#button-dataviz').html('<span class="icon"></span>');

        // Define URL
        var newDatavizLink = window.location.origin + '/statistiques/';
        $('#mapmenu li.dataviz a').attr('href', newDatavizLink);
        $('#mapmenu li.dataviz a').attr('target', '_blank');
    }
});
