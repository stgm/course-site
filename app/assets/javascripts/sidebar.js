// Automatically close the offcanvas "sidebar" when navigating
// this ensures that everything is clean when navigating back/forward afterwards

document.addEventListener("turbo:load", function() {
    e = document.getElementById("sidebar");
    e.classList.remove("show");
    oc = bootstrap.Offcanvas.getInstance(document.getElementById("sidebar"));
    if(oc) oc.dispose();
});
