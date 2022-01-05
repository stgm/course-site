import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "input", "button" ]

    deactivateButtons() {
        for (var button of this.buttonTargets)
            button.classList.remove('active');
    }

    activateButton(button) {
        this.deactivateButtons();
        button.classList.add('active');
    }

    change(event)
    {
        this.inputTarget.value = event.target.dataset.value;
        this.activateButton(event.target);
        Rails.fire(event.target.form, 'submit');
    }
}
