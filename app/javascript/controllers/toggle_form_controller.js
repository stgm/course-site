import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        const checkbox = this.element.querySelector('input[type="checkbox"]')
        if (checkbox) {
            checkbox.addEventListener("change", () => {
                this.element.requestSubmit()
                requestAnimationFrame(() => {
                    checkbox.disabled = true
                    setTimeout(() => checkbox.disabled = false, 500)
                })
            })
        }
    }
}
