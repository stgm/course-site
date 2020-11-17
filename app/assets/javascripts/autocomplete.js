function hookupAutocompletes()
{
	allAutocompletes = document.querySelectorAll(".autocomplete");

	allAutocompletes.forEach(
		(elt) =>
		{
			autocompleteForm = elt.querySelector("form");
			autocompleteInput = elt.querySelector("form input");
			autocompleteResults = elt.querySelector(".autocomplete-results");
			
			console.log([autocompleteForm,autocompleteInput,autocompleteResults])

			autocompleteInput.addEventListener('focus', (e) =>
			{
				if(autocompleteResults.childElementCount > 0)
					autocompleteResults.style.display = 'block';
			})

			autocompleteInput.addEventListener('paste', () =>
			{
				Rails.fire(autocompleteForm, 'submit')
			})

			autocompleteInput.addEventListener('input', () =>
			{
				Rails.fire(autocompleteForm, 'submit')
			})

			autocompleteInput.addEventListener('keydown', (kbd) =>
			{
				if(kbd.which == 40 || kbd.which == 38) {
					autocompleteResults.children[0].focus();
				}
			})

			autocompleteResults.addEventListener('keydown', (kbd) =>
			{
				console.log(kbd.target)
				if(kbd.which == 40 && kbd.target != null) {
					autocompleteResults.getElementById(kbd.target).nextSibling.focus();
				}
				if(kbd.which == 38 && kbd.target != null) {
					autocompleteResults.getElementById(kbd.target).previousSibling.focus();
				}
			})
		}
	)
}

document.addEventListener('turbolinks:load', hookupAutocompletes);
