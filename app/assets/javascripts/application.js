// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery.purr
//= require turbolinks
//= require rails-ujs
//= require popper
//= require bootstrap
//= require best_in_place
//= require garlic
//= require Chart.bundle
//= require chartkick
//= require twitter/typeahead
//= require_tree .


document.addEventListener('ajax:before', () => {
	Turbolinks.clearCache();
})

document.addEventListener("turbolinks:load", () => {
	$('[data-persist=garlic]').garlic();
})
