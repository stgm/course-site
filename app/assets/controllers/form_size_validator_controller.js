import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    maxSizeMb: { type: Number, default: 9 }
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
      alert(`Total file size exceeds ${this.maxSizeMbValue}MB.`)
    } else {
      this.disableSubmitButtons()
    }
  }

  disableSubmitButtons() {
    const buttons = this.element.querySelectorAll('button[type="submit"], input[type="submit"]')
    buttons.forEach(button => {
      button.disabled = true
      button.dataset.originalText = button.innerHTML
      button.innerHTML = "Submitting..." // optional: update the label
    })
  }
}
