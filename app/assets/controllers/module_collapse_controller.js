import { Controller } from "@hotwired/stimulus";

// Collapsing a module narrows all of its columns to a sliver: the per-pset
// dropdowns and the text inside the grade buttons are hidden, so only the
// grade colours remain. The choice is stored on the user, per schedule, so it
// follows them to another browser.

export default class extends Controller {
    static values = { schedule: String, url: String, collapsed: Array };

    connect() {
        this.apply();
    }

    toggle(event) {
        var name = event.currentTarget.dataset.module;
        if (!name) return;

        var collapsed = this.collapsedValue.slice();
        var index = collapsed.indexOf(name);
        if (index === -1) {
            collapsed.push(name);
        } else {
            collapsed.splice(index, 1);
        }
        this.collapsedValue = collapsed;

        this.apply();
        this.save();
    }

    apply() {
        var collapsed = this.collapsedValue;
        this.element.querySelectorAll("[data-module]").forEach(function (cell) {
            cell.classList.toggle("module-collapsed", collapsed.indexOf(cell.dataset.module) !== -1);
        });
    }

    save() {
        var token = document.querySelector("meta[name='csrf-token']");
        fetch(this.urlValue, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": token ? token.content : ""
            },
            body: JSON.stringify({ schedule: this.scheduleValue, modules: this.collapsedValue })
        });
    }
}
