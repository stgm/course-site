// Allows direct hash links to tabs, and updates window.location when changing
// tabs to include the tab-id after the hash.

// finds and activates a tab belonging to current window location hash
function find_and_activate_tab() {
	 var hash = window.location.hash;
	 var tab_content_id = hash + '-content';
	 if (tab_content_id.length > 0) {
		  var toggle = $('a[data-toggle=tab][data-target=' + tab_content_id + ']');
		  toggle.tab('show');
		  window.scrollTo(0, 0);
	 }
}

// handling manipulation of the address bar and page-local links
$(window).on('hashchange', find_and_activate_tab);

$(document).ready(function() {
	 // handling regular clicks on tabs
	 $('a[data-toggle=tab]').on('shown.bs.tabs', function() {
		  console.log('tab shown');
		  var hash = document.location.hash;
		  var active_tab_id = $(this).attr('data-target').slice(0, -8);
		  if (hash != active_tab_id) {
				console.log('changing location hash');
	 			window.location.hash = active_tab_id;
		  }
	 });

	 // handling direct links from another page
	 find_and_activate_tab();
});
