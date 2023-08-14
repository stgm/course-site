// Automatically close the offcanvas "sidebar" when navigating
// this ensures that everything is clean when navigating back/forward afterwards

document.addEventListener("turbo:load", function() {
    x = bootstrap.Offcanvas.getInstance(document.getElementById("sidebar"));
    if(x) x.hide();
});
