import { Controller } from "@hotwired/stimulus";

// Editable fields are saved when they lose focus. The handlers live here
// rather than on the fields themselves, since the overview holds one field
// per student.

export default class extends Controller {
    connect() {
        this.onFocus = this.onFocus.bind(this);
        this.onBlur = this.onBlur.bind(this);
        this.onKeyPress = this.onKeyPress.bind(this);

        // focus and blur do not bubble, their focusin and focusout twins do
        this.element.addEventListener("focusin", this.onFocus);
        this.element.addEventListener("focusout", this.onBlur);
        this.element.addEventListener("keypress", this.onKeyPress);
    }

    disconnect() {
        this.element.removeEventListener("focusin", this.onFocus);
        this.element.removeEventListener("focusout", this.onBlur);
        this.element.removeEventListener("keypress", this.onKeyPress);
    }

    field(event) {
        return event.target.closest(".in_place_editable");
    }

    onFocus(event) {
        if (!this.field(event)) return;
        window.setTimeout(() => document.execCommand("selectAll", false, null));
    }

    onKeyPress(event) {
        var field = this.field(event);
        if (!field || event.keyCode !== 13) return;
        event.preventDefault();
        field.blur();
    }

    onBlur(event) {
        var field = this.field(event);
        if (field) this.save(field);
    }

    save(field) {
        var data = field.dataset;
        var token = document.querySelector("meta[name='csrf-token']");
        var body = new URLSearchParams();
        body.set("id", data.id);
        body.set(data.model + "[" + data.property + "]", field.textContent);

        field.classList.remove("error");
        field.classList.add("saving");

        fetch(data.url, {
            method: "PUT",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded",
                "X-CSRF-Token": token ? token.content : ""
            },
            body: body
        }).then((response) => {
            field.classList.remove("saving");
            if (!response.ok) field.classList.add("error");
        }).catch(() => {
            field.classList.remove("saving");
            field.classList.add("error");
        });
    }
}
