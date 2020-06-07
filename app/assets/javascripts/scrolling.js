// persist scrolls
// from https://github.com/turbolinks/turbolinks-classic/issues/205
var elementsWithPersistentScrolls, persistentScrollsPositions;

// assign this class to a scrollable element to have it remain in position on page navigation
elementsWithPersistentScrolls = ['.turbolinks-disable-scroll'];

persistentScrollsPositions = {};

$(document).on('turbolinks:before-visit', function() {
    var i, len, results, selector;
    persistentScrollsPositions = {};
    results = [];
    for (i = 0, len = elementsWithPersistentScrolls.length; i < len; i++) {
        selector = elementsWithPersistentScrolls[i];
        results.push(persistentScrollsPositions[selector] = $(selector).scrollTop());
    }
    return results;
});

$(document).on('turbolinks:load', function() {
    var results, scrollTop, selector;
    results = [];
    for (selector in persistentScrollsPositions) {
        scrollTop = persistentScrollsPositions[selector];
        results.push($(selector).scrollTop(scrollTop));
    }
    return results;
});
