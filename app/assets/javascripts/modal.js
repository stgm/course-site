function hookupModals()
{
    console.log("HAAI")
  
    // wait for user confirmation before showing modal for these buttons
    $('a[data-trigger=modal]').on('confirm:complete', function(e, response) {
        if(response) {
            $('#modal-browser').modal('show');
        }
    });
    
    $('a[data-trigger=modal]:not([data-confirm])').val( "has man in it!" )
    
    // for buttons without confirmation, show the modal immediately
    $('a[data-trigger=modal]:not([data-confirm])').on('click', function() {
        $('#modal-browser').modal('show');
    });
}

// $(hookupModals);
$(document).on('turbolinks:load', hookupModals);
