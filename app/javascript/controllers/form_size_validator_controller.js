import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        maxSizeMb: { type: Number, default: 9 } // max size in MB
    }

    connect() {
        this.element.addEventListener("submit", this.validate.bind(this))
    }

    validate(event) {
        const fileInputs = this.element.querySelectorAll('input[type="file"]')
        let totalSize = 0

        fileInputs.forEach(input => {
            for (let i = 0; i < input.files.length; i++) {
                totalSize += input.files[i].size
            }
        })

        const maxSizeBytes = this.maxSizeMbValue * 1024 * 1024

        if (totalSize > maxSizeBytes) {
            event.preventDefault()
            alert(`Total file size exceeds ${this.maxSizeMbValue}MB, which is too large. Consider removing large data files or other stuff that's not needed.'`)
        }
    }
}
