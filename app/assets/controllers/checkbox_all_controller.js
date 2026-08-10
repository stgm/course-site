import { Controller } from "@hotwired/stimulus"

// A single "select all" checkbox that toggles every other checkbox in the form.
export default class extends Controller {
    static targets = ["all", "item"]

    toggle() {
        for (var item of this.itemTargets) item.checked = this.allTarget.checked
    }
}
