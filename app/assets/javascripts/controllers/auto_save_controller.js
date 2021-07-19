import { Controller } from "stimulus"

export default class extends Controller {
    static targets = [ "form", "badge" ]

    connect() 
    {
        var saveTimeout;
        var form = this.formTarget;
        var badge = this.badgeTarget;
        var x = this.formTarget.elements;

        for (var item of x)
        {
            item.addEventListener("input", () =>
            {
                this.badgeTarget.innerHTML = 'unsaved';
                clearTimeout(saveTimeout);             // typing delays autosaving
                saveTimeout = setTimeout(function() {
                    Rails.fire(form, 'submit')
                    badge.innerHTML = 'saved';
                }, 500);   // this is the autosave interval
            })
        }

        document.addEventListener('turbo:before-cache', function () {
            document.querySelectorAll('[autofocus]').forEach(e => e.removeAttribute('autofocus'));
        })
    }
}
