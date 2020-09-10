var GRADE_PASS = -1;
var GRADE_FAIL =  0;

function deactivate_buttons() {
	$('button#pass-btn').removeClass('active');
	$('button#fail-btn').removeClass('active');
}

function activate_button(button) {
	deactivate_buttons();
	button.addClass('active');
}

$(document).on('ready turbolinks:load', function () {
	$('button#pass-btn').click(function(e) {
		$('#grade_grade').val(GRADE_PASS);
		activate_button($(this));
		Rails.fire(document.getElementById('grade-form'), 'submit')
		e.preventDefault();
	});

	$('button#fail-btn').click(function(e) {
		$('#grade_grade').val(GRADE_FAIL);
		activate_button($(this));
		Rails.fire(document.getElementById('grade-form'), 'submit')
		e.preventDefault();
	});

	$('#grade_grade').change(function(e) {
		deactivate_buttons();
	});
});
