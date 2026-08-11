import { Controller } from "@hotwired/stimulus"

// Enables this element only while something is selected elsewhere on the page,
// per the "grades:selection" event broadcast by checkbox_all_controller.
export default class extends Controller {
    updateFromSelection(event) {
        this.element.disabled = !event.detail.any
    }
}
