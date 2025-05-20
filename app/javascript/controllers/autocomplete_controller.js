import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autocomplete"
export default class extends Controller {
    static targets = ["form", "input", "results"]

    connect() {
        this.inputTarget.addEventListener('paste', () => {
            this.formTarget.requestSubmit();
        });

        this.inputTarget.addEventListener('input', () => {
            this.formTarget.requestSubmit();
        });

        this.inputTarget.addEventListener('keydown', (event) => {
            const results = this.resultsTarget;
            if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
                const firstItem = results.querySelector('.dropdown-item');
                if (firstItem) {
                    firstItem.focus();
                    event.preventDefault();
                }
            }
            if (event.key === 'Escape') {
                this.inputTarget.value = "";
                this.formTarget.requestSubmit();
            }
        });
    }
}
