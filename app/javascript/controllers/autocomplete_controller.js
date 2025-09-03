import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["form", "input", "results", "menu"];
    activeIndex = -1;

    connect() {
        // submit on change
        this.inputTarget.addEventListener("input", () => this.formTarget.requestSubmit());
        this.inputTarget.addEventListener("paste", () => this.formTarget.requestSubmit());

        // from input → open + focus first/last
        this.inputTarget.addEventListener("keydown", (e) => {
            if (e.key === "ArrowDown") {
                e.preventDefault();
                this.syncVisibility();
                if (this.items.length) this.setActive(0, { focus: true });
            } else if (e.key === "ArrowUp") {
                e.preventDefault();
                this.syncVisibility();
                if (this.items.length) this.setActive(this.items.length - 1, { focus: true });
            } else if (e.key === "Escape") {
                this.inputTarget.value = "";
                this.formTarget.requestSubmit();
                this.hideMenu();
            }
        });

        // delegate events from inside the turbo-frame
        this.resultsTarget.addEventListener("keydown", (e) => this.onMenuKeydown(e));
        this.resultsTarget.addEventListener("mousemove", (e) => this.onMenuMousemove(e));
        this.resultsTarget.addEventListener("click", (e) => this.onMenuClick(e));

        // when frame updates, ensure visibility matches content
        this.element.addEventListener("turbo:frame-load", (e) => {
            if (e.target.id !== "search-results-frame") return;
            this.syncVisibility();
        });

        this.syncVisibility();
    }

    // --- helpers ---
    get items() {
        const root = this.menuTarget || this.resultsTarget;
        return Array.from(root.querySelectorAll(".dropdown-item:not([disabled])"));
    }

    showMenu() {
        if (!this.menuTarget) return;
        this.menuTarget.classList.add("show");
        this.menuTarget.setAttribute("aria-hidden", "false");
        this.inputTarget.setAttribute("aria-expanded", "true");
    }

    hideMenu() {
        if (!this.menuTarget) return;
        this.menuTarget.classList.remove("show");
        this.menuTarget.setAttribute("aria-hidden", "true");
        this.inputTarget.setAttribute("aria-expanded", "false");
        this.clearActive();
    }

    syncVisibility() {
        if (this.items.length && this.inputTarget.value.trim() !== "") {
            this.showMenu();
        } else {
            this.hideMenu();
        }
    }

    // --- active item management ---
    clearActive() {
        if (this.activeIndex >= 0 && this.items[this.activeIndex]) {
            this.items[this.activeIndex].classList.remove("active");
        }
        this.activeIndex = -1;
    }

    setActive(index, { focus = false } = {}) {
        const items = this.items;
        if (!items.length) return;
        if (this.activeIndex >= 0 && items[this.activeIndex]) {
            items[this.activeIndex].classList.remove("active");
        }
        this.activeIndex = ((index % items.length) + items.length) % items.length;
        const el = items[this.activeIndex];
        el.classList.add("active");
        el.setAttribute("aria-selected", "true");
        if (focus) el.focus({ preventScroll: true });
    }

    // --- menu interactions ---
    onMenuKeydown(e) {
        // Only handle keys if the event originated in our menu
        if (!e.target.closest || !e.target.closest(".autocomplete-menu")) return;
        const n = this.items.length;
        if (!n) return;

        switch (e.key) {
            case "ArrowDown":
                e.preventDefault();
                this.setActive(this.activeIndex === -1 ? 0 : this.activeIndex + 1, { focus: true });
                break;
            case "ArrowUp":
                e.preventDefault();
                this.setActive(this.activeIndex === -1 ? n - 1 : this.activeIndex - 1, {
                    focus: true,
                });
                break;
            case "Home":
                e.preventDefault();
                this.setActive(0, { focus: true });
                break;
            case "End":
                e.preventDefault();
                this.setActive(n - 1, { focus: true });
                break;
            case "Enter":
            case " ":
                e.preventDefault();
                if (this.activeIndex >= 0) this.items[this.activeIndex].click();
                break;
            case "Escape":
                e.preventDefault();
                this.hideMenu();
                this.inputTarget.focus();
                break;
            case "Tab":
                this.hideMenu(); // let focus move naturally
                break;
        }
    }

    onMenuMousemove(e) {
        const el = e.target.closest && e.target.closest(".dropdown-item");
        if (!el) return;
        const idx = this.items.indexOf(el);
        if (idx !== -1 && idx !== this.activeIndex) this.setActive(idx);
    }

    onMenuClick(_e) {
        this.hideMenu(); // allow Turbo/anchor default navigation
    }
}

// Thanks, Chat
