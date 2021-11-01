lizMap.events.on({
    'uicreated': function (evt) {
        console.log('Import module ON');

        // Handle form submit
        $('#jforms_occtax_import').submit(function () {
            return false;
        });
    }
});
