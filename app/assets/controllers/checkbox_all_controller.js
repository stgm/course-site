import { Controller } from "@hotwired/stimulus"

// A "select all" checkbox that toggles every item checkbox, plus broadcasting
// whether anything is selected, for the footer button (elsewhere in the modal,
// outside this controller's own element) to enable or disable itself.
export default class extends Controller {
    static targets = [ "all", "item" ]

    connect() {
        this.broadcast()
    }

    toggleAll() {
        for (var item of this.itemTargets) item.checked = this.allTarget.checked
        this.broadcast()
    }

    itemChanged() {
        this.broadcast()
    }

    broadcast() {
        var any = this.itemTargets.some((item) => item.checked)
        window.dispatchEvent(new CustomEvent("grades:selection", { detail: { any: any } }))
    }
}
