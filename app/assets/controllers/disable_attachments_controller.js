import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    connect() {
        // Get the Trix editor element
        const editor = this.element;

        // Add an event listener for the Trix attachment event
        editor.addEventListener("trix-file-accept", (event) => {
            // Prevent the attachment from being added to the editor
            event.preventDefault();
        });
    }
}
