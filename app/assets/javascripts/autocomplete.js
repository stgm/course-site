function hookupAutocompletes()
{
	allAutocompletes = document.querySelectorAll(".autocomplete");

	allAutocompletes.forEach(
		(elt) =>
		{
			autocompleteForm = elt.querySelector("form");
			autocompleteInput = elt.querySelector("form input");
			autocompleteResults = elt.querySelector(".autocomplete-results");

			autocompleteInput.addEventListener('focus', (e) =>
			{
				if(autocompleteResults.childElementCount > 0)
					autocompleteResults.classList.add('show');
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
				if(kbd.key == 'ArrowDown' || kbd.key == 'ArrowUp') {
					autocompleteResults.children[0].focus();
					kbd.preventDefault();
				}
			})
		}
	)
}

document.addEventListener('turbolinks:load', hookupAutocompletes);
