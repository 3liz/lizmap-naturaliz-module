lizMap.events.on({
    'uicreated':function(evt){
        // Add empty dock
        lizMap.addDock('dataviz', 'Statistiques', 'dock', '', 'icon-signal');

        // Use standard Dataviz menu icon
        $('#button-dataviz').html('<span class="icon"></span>');

        // Define URL
        var newDatavizLink = window.location.origin + '/dev/index.php/view/map/?repository=rep1&project=stat_naturaliz';
        $('#mapmenu li.dataviz a').attr('href', newDatavizLink);
        $('#mapmenu li.dataviz a').attr('target', '_blank');
    }
});
