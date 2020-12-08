// persist scrolls
// from https://github.com/turbolinks/turbolinks-classic/issues/205
var elementsWithPersistentScrolls, persistentScrollsPositions;

// assign this class to a scrollable element to have it remain in position on page navigation
elementsWithPersistentScrolls = [];
persistentScrollsPositions = [];

document.addEventListener('turbolinks:before-visit', () => {
	elementsWithPersistentScrolls = document.querySelectorAll('.turbolinks-disable-scroll');
	persistentScrollsPositions = [];
	for (i = 0, len = elementsWithPersistentScrolls.length; i < len; i++)
	{
		element = elementsWithPersistentScrolls[i];
		persistentScrollsPositions.push(element.scrollTop);
	}
})

document.addEventListener('turbolinks:load', () => {
	results = [];
	for (i = 0, len = elementsWithPersistentScrolls.length; i < len; i++)
	{
		element = elementsWithPersistentScrolls[i];
		scrollTop = persistentScrollsPositions[i];
		element.scrollTop = scrollTop;
	}
})
