import { Controller } from "@hotwired/stimulus"

// Auto-reload the turbo frame after an operation. Used for the case of
// downloading a final grade sheet, after which the page needs to be
// updated to not show old data.
const RELOAD_DELAY_MS = 1000

export default class extends Controller {
    static values = { frame: String }

    clicked() {
        setTimeout(() => {
            var frame = document.getElementById(this.frameValue)
            if (frame) frame.reload()
        }, RELOAD_DELAY_MS)
    }
}
