function startAutosave()
{
	var saveTimeout;
	x = document.getElementById('grade-form').elements;

	for (item of x)
	{
		item.addEventListener("input", () =>
		{
			document.getElementById('grade-badge').innerHTML = 'unsaved'
			clearTimeout(saveTimeout);  // typing delays autosaving
			saveTimeout = setTimeout(
				function()
				{
					Rails.fire(document.getElementById('grade-form'), 'submit')
					document.getElementById('grade-badge').innerHTML = 'saved'
				},
				500  // this is the autosave interval
			)
		})
	}

	document.addEventListener('turbolinks:before-cache', function () {
		document.querySelectorAll('[autofocus]').forEach(e => e.removeAttribute('autofocus'));
	})
}
