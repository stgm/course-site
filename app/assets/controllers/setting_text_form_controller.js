import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.element.addEventListener("turbo:submit-end", () => {
            const button = this.element.querySelector('button[type="submit"], input[type="submit"]')
            if (button) {
                button.disabled = true
                setTimeout(() => {
                    button.disabled = false
                }, 500)
            }
        })
    }
}
