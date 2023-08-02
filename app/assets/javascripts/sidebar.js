// Automatically close the "sidebar" when navigating
// this ensures that everything is clean when navigating back/forward afterwards

document.addEventListener("turbo:before-visit", function() {
    e = document.getElementById("sidebar");
    if (e) e.classList.remove("show");
    e = document.getElementById("navbar_links");
    if (e) e.classList.remove("show");
});
