import { Controller } from "@hotwired/stimulus";

// Two jobs in the grade entry grid: show what each row would come out as while
// it is being typed, and put the grader back where they were after a save.

const DEBOUNCE_MS = 150;

export default class extends Controller {
    static values = { url: String, key: String };

    connect() {
        this.timers = new Map();
        this.requests = new Map();
        this.restore();
    }

    disconnect() {
        for (var timer of this.timers.values()) clearTimeout(timer);
        for (var request of this.requests.values()) request.abort();
    }

    // the live preview

    preview(event) {
        if (!event.target.hasAttribute("data-subgrade")) return;
        var row = event.target.closest("tr[data-user-id]");
        if (!row) return;

        clearTimeout(this.timers.get(row));
        this.timers.set(row, setTimeout(() => this.calculate(row), DEBOUNCE_MS));
    }

    async calculate(row) {
        var params = new URLSearchParams();
        params.set("user_id", row.dataset.userId);
        for (var input of row.querySelectorAll("[data-subgrade]")) {
            params.set("subgrades[" + input.dataset.subgrade + "]", input.value);
        }

        // a fast typist should not be overtaken by their own earlier keystrokes
        var previous = this.requests.get(row);
        if (previous) previous.abort();
        var request = new AbortController();
        this.requests.set(row, request);

        try {
            var response = await fetch(this.urlValue + "?" + params, {
                credentials: "same-origin",
                signal: request.signal,
            });
            if (response.ok) this.fill(row, await response.json());
        } catch (error) {
            // an abandoned request is the normal case here, not a failure
            if (error.name !== "AbortError") throw error;
        }
    }

    fill(row, result) {
        var calculated = row.querySelector("[data-calculated]");
        var aggregate = row.querySelector("[data-aggregate]");
        // a row that cannot be calculated yet shows nothing rather than a dash
        if (calculated) calculated.value = result.grade === null ? "" : result.display;
        if (aggregate) aggregate.value = result.aggregate === null ? "" : result.aggregate;
    }

    // keeping our place across a save, which reloads the whole frame

    remember(event) {
        if (event.target.name) this.focused = event.target.name;
    }

    store() {
        sessionStorage.setItem(this.keyValue, JSON.stringify({
            scrollTop: this.scroller ? this.scroller.scrollTop : 0,
            scrollLeft: this.scroller ? this.scroller.scrollLeft : 0,
            focused: this.focused,
        }));
    }

    restore() {
        var stored = sessionStorage.getItem(this.keyValue);
        if (!stored) return;
        sessionStorage.removeItem(this.keyValue);
        var state = JSON.parse(stored);

        // named lookup through the form, so the brackets need no escaping
        var cell = state.focused && this.form && this.form.elements[state.focused];
        if (cell) {
            cell.focus();
            cell.select();
        }

        // focusing scrolls the cell into view, so the scroll position goes last
        requestAnimationFrame(() => {
            if (!this.scroller) return;
            this.scroller.scrollTop = state.scrollTop;
            this.scroller.scrollLeft = state.scrollLeft || 0;
        });
    }

    get form() {
        return this.element.querySelector("form");
    }

    get scroller() {
        return document.getElementById("modal-browser-body");
    }
}
