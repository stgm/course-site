import { Controller } from "@hotwired/stimulus"

// Reloads the turbo frame around this element every few seconds. The element
// sits inside the frame, so each reload replaces it and restarts the timer;
// that means a slow response never overlaps with the next request.
export default class extends Controller {
    static values = { url: String, interval: Number }

    connect() {
        this.timer = setTimeout(() => this.tick(), this.intervalValue * 1000)
    }

    disconnect() {
        clearTimeout(this.timer)
    }

    tick() {
        const frame = this.element.closest("turbo-frame")
        // wait while the tab is hidden, a modal is open or a switch is being saved
        const busy = document.hidden
            || document.querySelector("#modal-browser.show")
            || this.element.querySelector("input:disabled")
        if (!frame || busy) {
            this.timer = setTimeout(() => this.tick(), this.intervalValue * 1000)
        } else if (frame.src) {
            frame.reload()
        } else {
            frame.src = this.urlValue
        }
    }
}
