function hookupModals()
{
    // wait for user confirmation before showing modal for these buttons
    document.querySelectorAll('a[data-trigger=modal]').forEach(
        (elt) => {
            elt.addEventListener('confirm:complete',
                (e, response) => {
                    if(e.detail[0]) {
                        $('#modal-browser').modal('show');
                    }
                }
            )
        }
    )
    
    // for buttons without confirmation, show the modal immediately
    $('a[data-trigger=modal]:not([data-confirm])').on('click', function() {
        $('#modal-browser').modal('show');
    });
}

// $(hookupModals);
$(document).on('turbolinks:load', hookupModals);
