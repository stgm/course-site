import { Controller } from "@hotwired/stimulus";

// Fades its element out shortly after it appears, for confirmations that have
// been read by the time they are noticed.

const DEFAULT_DELAY = 1000;

export default class extends Controller {
    static values = { after: Number };

    connect() {
        this.timer = setTimeout(
            () => this.element.classList.add("dismissed"),
            this.afterValue || DEFAULT_DELAY
        );
    }

    disconnect() {
        clearTimeout(this.timer);
    }
}
