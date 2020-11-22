// data-trigger=model buttons are used in the grade overview

var modalBrowser;

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

	modalBrowserElement = document.getElementById('modal-browser');
	modalBrowser = new bootstrap.Modal(modalBrowserElement);
	modalBrowserElement.addEventListener('show.bs.modal', function (e) {
		// clear modal upon load
		document.getElementById('modal-browser-header').innerHTML = '';
		document.getElementById('modal-browser-body').innerHTML = '<div class="text-center"><div class="spinner-grow" style="width: 3rem; height: 3rem;" role="status"><span class="visually-hidden">Loading...</span></div></div>';
	})
}

document.addEventListener('turbolinks:load', hookupModals);
