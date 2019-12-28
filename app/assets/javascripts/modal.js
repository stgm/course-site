$(function() {
    // wait for user confirmation before showing modal for these buttons
    $('a[data-trigger=modal]').on('confirm:complete', function(e, response) {
        if(response) {
            $('#modal-browser').modal('show');
        }
    });

    // for buttons without confirmation, show the modal immediately
    $('a[data-trigger=modal]:not([data-confirm])').on('click', function() {
        $('#modal-browser').modal('show');
    });
})
