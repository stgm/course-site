import { Controller } from "@hotwired/stimulus";

// The whole grade cell is clickable, not just the label inside it. One
// delegated handler does that for the entire table, so the cells need no
// overlay of their own.

export default class extends Controller {
    connect() {
        this.onClick = this.onClick.bind(this);
        this.element.addEventListener("click", this.onClick);
    }

    disconnect() {
        this.element.removeEventListener("click", this.onClick);
    }

    onClick(event) {
        // clicks that already landed on something interactive are its own
        if (event.target.closest("a, button, [contenteditable]")) return;

        var cell = event.target.closest("td");
        var button = cell && cell.querySelector(".grade-button");
        if (!button) return;
        if (button.tagName !== "A" && button.tagName !== "BUTTON") return;

        button.click();
    }
}
