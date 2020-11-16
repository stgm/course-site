// data-trigger=model buttons are used in the grade overview

function hookupModals()
{
    // wait for user confirmation before showing modal for these buttons
    document.querySelectorAll('a[data-trigger=modal]').forEach(
        (elt) => {
            elt.addEventListener('confirm:complete',
                (e, response) => {
                    if(e.detail[0]) {
                        modalBrowser.show()
                    }
                }
            )
        }
    )
    
    // for buttons without confirmation, show the modal immediately
    document.querySelectorAll('a[data-trigger=modal]:not([data-confirm])').forEach(
        (elt) => { elt.addEventListener('click', () => modalBrowser.show()) }
    );
}

document.addEventListener('turbolinks:load', hookupModals);
