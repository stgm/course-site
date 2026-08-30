// Modals here are not opened the Bootstrap way. Bootstrap opens a modal from
// a data-bs-toggle="modal" trigger that points at markup already present in
// the page. Instead, a trigger carries data-turbo-frame=modal, and Turbo loads
// the response into the <turbo-frame id="modal"> that lives inside
// #modal-browser. So two separate things have to happen on a click: Turbo
// fetches the content, and we open the Bootstrap modal that will hold it. Only
// the second half is our job; that is what the listeners below do.
//
// Opening the shell immediately, before the content arrives, is what puts the
// spinner on screen while the frame loads.

// The one Bootstrap modal instance wrapping #modal-browser. Rebuilt on every
// visit, because Turbo replaces the element it was built around.
var modalBrowser;

var MODAL_TRIGGERS = 'a[data-turbo-frame=modal], form[data-turbo-frame=modal] button, button[data-turbo-frame=modal]';
var MODAL_TRIGGERS_WITHOUT_CONFIRM = 'a[data-turbo-frame=modal]:not([data-confirm])';

function modalTrigger(event, selector)
{
	if (!modalBrowser) return null;
	if (!event.target || !event.target.closest) return null;
	return event.target.closest(selector);
}

// One delegated listener per event instead of one per button: the grade
// overview holds hundreds of these, and they are re-rendered on every visit.
// Both events bubble, so document sees them all.

// A trigger with data-confirm has its click cancelled by rails-ujs, which
// asks the question and then fires confirm:complete with the answer. Opening
// on the click would show an empty modal for a cancelled action, so these wait
// for the answer instead.
document.addEventListener('confirm:complete', function (event) {
	if (!modalTrigger(event, MODAL_TRIGGERS)) return;
	if (event.detail[0]) modalBrowser.show();
});

// Everything else opens straight away, on the same click Turbo acts on.
document.addEventListener('click', function (event) {
	if (!modalTrigger(event, MODAL_TRIGGERS_WITHOUT_CONFIRM)) return;
	modalBrowser.show();
});

function hookupModals()
{
	// Bootstrap keeps its state on the instance, so a new element needs a new
	// one. The delegated listeners above read this variable at click time and
	// therefore always use the current instance.
	modalBrowserElement = document.getElementById('modal-browser');
	modalBrowser = new bootstrap.Modal(modalBrowserElement);
	// Bootstrap fires this on every open. The frame still holds the previous
	// modal's content at this point, so it is reset here rather than on close,
	// which would make the old content vanish during the closing animation.
	modalBrowserElement.addEventListener('show.bs.modal', function (e) {
		// back to the default width, in case the last modal widened itself
		document.getElementById('modal-browser-dialog').className = 'modal-dialog modal-dialog-scrollable modal-lg modal-fullscreen-sm-down';
		// clear modal upon load
		// document.getElementById('modal-browser-header').innerHTML = '';
		document.getElementById('modal-browser-dialog').innerHTML = '<turbo-frame id="modal"><div class="modal-content"><div id="modal-browser-body"><div class="text-center"><div class="spinner-grow" style="width: 3rem; height: 3rem;" role="status"><span class="visually-hidden">Loading...</span></div></div></div></div></turbo-frame>';
	})
}

document.addEventListener('turbo:load', hookupModals);
