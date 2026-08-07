import { Controller } from "@hotwired/stimulus";

// The modal dialog lives in the page, not in the turbo-frame, so content that
// needs more room than the default has to reach out and widen it.

const DEFAULT_SIZE = "lg";

export default class extends Controller {
    static values = { size: String };

    connect() {
        this.resize(this.sizeValue || DEFAULT_SIZE);
    }

    disconnect() {
        this.resize(DEFAULT_SIZE);
    }

    resize(size) {
        var dialog = document.getElementById("modal-browser-dialog");
        if (!dialog) return;
        dialog.classList.remove("modal-sm", "modal-lg", "modal-xl");
        dialog.classList.add("modal-" + size);
    }
}
