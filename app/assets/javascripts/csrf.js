// TODO weird that it's needed to copy CSRF tokens to forms on page transition

document.addEventListener("turbo:load", function (event) {
    // copy the CSRF token from the body to the form elements
    let csrfToken = document.querySelector("meta[name='csrf-token']").content;
    document.querySelectorAll("form input[name='authenticity_token']").forEach(function (el) {
        el.value = csrfToken;
    });
});
