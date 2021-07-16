// Persist scroll positions for selected elements when navigating between pages
// from https://github.com/turbolinks/turbolinks-classic/issues/205
// To use, assign restore-scroll-position to any scrollable element

var persistentScrollsPositions = []

document.addEventListener('turbo:before-visit', () => {

	elementsWithPersistentScrolls = document.querySelectorAll('.restore-scroll-position')
	persistentScrollsPositions = []

	for (i = 0, len = elementsWithPersistentScrolls.length; i < len; i++)
	{
		element = elementsWithPersistentScrolls[i]
		persistentScrollsPositions.push(element.scrollTop)
	}

})

document.addEventListener('turbo:load', () => {

	elementsWithPersistentScrolls = document.querySelectorAll('.restore-scroll-position')

	for (i = 0, len = elementsWithPersistentScrolls.length; i < len; i++)
	{
		element = elementsWithPersistentScrolls[i]
		scrollTop = persistentScrollsPositions[i]
		element.scrollTop = scrollTop
	}

})
