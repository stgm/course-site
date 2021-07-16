var GRADE_PASS = -1;
var GRADE_FAIL =  0;

function deactivate_buttons() {
	document.getElementById('pass-btn').classList.remove('active');
	document.getElementById('fail-btn').classList.remove('active');
}

function activate_button(button) {
	deactivate_buttons();
	button.classList.add('active');
}

function activate_grade_buttons()
{
	passButton = document.getElementById('pass-btn');
	failButton = document.getElementById('fail-btn');

	if(passButton)
	{
		passButton.addEventListener('click', function(e) {
			document.getElementById('submit_grade_attributes_grade').value = GRADE_PASS;
			activate_button(this);
			Rails.fire(document.getElementById('grade-form'), 'submit');
			e.preventDefault();
		});

		failButton.addEventListener('click', function(e) {
			document.getElementById('submit_grade_attributes_grade').value = GRADE_FAIL;
			activate_button(this);
			Rails.fire(document.getElementById('grade-form'), 'submit');
			e.preventDefault();
		});

		document.getElementById('submit_grade_attributes_grade').addEventListener('change', deactivate_buttons);
	}
}

document.addEventListener('ready', activate_grade_buttons);
document.addEventListener('turbo:load', activate_grade_buttons);
